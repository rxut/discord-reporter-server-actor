class DiscordReporterStats_TDM extends DiscordReporterStats_DM;

var string sScoreStr;

// Override GetTeamColor Function
function string GetTeamColor(byte iTeam)
{
  // Do a switch and return the proper color
  switch (iTeam)
  {
    case 0:
      return conf.colRed;
    case 1:
      return conf.colBlue;
    case 2:
      return conf.colGreen;
    case 3:
      return conf.colGold;
    default:
      return conf.colBody;
  }
}

// Override InTeamMessage Function
function InTeamMessage(PlayerReplicationInfo PRI, coerce string S, name Type, optional bool bBeep)
{
  SendMessage(bold(PRI.PlayerName) $ ":" @ S);
}

// Post Player Statistics (overridden)
function PostPlayerStats()
{
  OnScoreDetails();
}

function SendRawMessage(string Message, optional bool bTime)
{
    local string FormattedMessage;

    // If message is empty, just send a newline
    if (Message == "")
    {
        Link.SendText(Chr(13) $ Chr(10));
        return;
    }

    // Format the message
    FormattedMessage = Message $ Chr(13) $ Chr(10);

    // Send the message
    Link.SendText(FormattedMessage);
}

function string GetFragText(int count)
{
    if (count == 1)
        return "Frag";
    return "Frags";
}

// Detailed Score Information (overridden)
function OnScoreDetails()
{
  local int i, iT;
  local PlayerReplicationInfo lPRI, bestPRI;
  local int j, playerCount;
  local PlayerReplicationInfo tempPRI;
  local int efficiency;
  local Pawn PlayerPawn;
  local PlayerReplicationInfo TeamArray[32];  // Temporary array for sorting
  local string CompleteMessage;
  local string sTimeMsg;
  local int maxNameLength;
  local int totalPlayers;
  local int teamSize[4];  // Store team sizes
  
  // First pass - collect all players and find longest name
  maxNameLength = 0;
  totalPlayers = 0;
  
  for (i = 0; i < 32; i++)
  {
    lPRI = TGRI.PRIArray[i];
    if (lPRI != None && !lPRI.bIsSpectator)
    {
      // Count total players
      totalPlayers++;
      
      // Track team sizes
      teamSize[lPRI.Team]++;
      
      // Find longest name
      if (Len(lPRI.PlayerName) > maxNameLength)
      {
        maxNameLength = Len(lPRI.PlayerName);
      }
      
      // Track best player
      if (bestPRI == None || bestPRI.Score < lPRI.Score)
      {
        bestPRI = lPRI;
      }
    }
  }
  
  // Ensure minimum padding (16 spaces)
  maxNameLength = Max(maxNameLength + 1, 10);

  // Build header
   if (TGRI.TimeLimit > 0)
  {
    if (int(TGRI.RemainingTime) == (TGRI.TimeLimit * 60))
      sTimeMsg = "Waiting For Start";
    else
      sTimeMsg = "Time Remaining: " $ GetStrTime(TGRI.RemainingTime);
  }
  else
  {
    sTimeMsg = "No Time Limit - Score Limit: " $ TGRI.FragLimit;
  }

  CompleteMessage = "```" $ Chr(13) $ Chr(10);
  CompleteMessage = CompleteMessage $ Level.Game.GameReplicationInfo.ServerName $ Chr(13) $ Chr(10);
  CompleteMessage = CompleteMessage $ Level.Game.GameName $ " - " $ 
                    Level.Title $ " - " $ 
                    totalPlayers $ "/" $ Level.Game.MaxPlayers $ " - " $  
                    sTimeMsg $ Chr(13) $ Chr(10);
  
  CompleteMessage = CompleteMessage $ Chr(13) $ Chr(10);

  // For each team
  for (iT = 0; iT < TeamGamePlus(Level.Game).MaxTeams; iT++)
  {
    if (teamSize[iT] == 0)
      continue;

    // Output team header
    CompleteMessage = CompleteMessage $ conf.sTeams[iT] $ " [" $ 
                     int(TeamGamePlus(Level.Game).Teams[iT].Score) $ " Frags]" $ 
                     Chr(13) $ Chr(10) $ Chr(13) $ Chr(10);
    
    // Collect and sort players for this team
    playerCount = 0;
    
    for (i = 0; i < 32; i++)
    {
      lPRI = TGRI.PRIArray[i];
      if (lPRI == None || lPRI.bIsSpectator || lPRI.Team != iT)
        continue;

      TeamArray[playerCount] = lPRI;
      playerCount++;
    }

    // Sort players by score
    for (i = 0; i < playerCount - 1; i++)
    {
      for (j = 0; j < playerCount - 1 - i; j++)
      {
        if (TeamArray[j].Score < TeamArray[j + 1].Score)
        {
          tempPRI = TeamArray[j];
          TeamArray[j] = TeamArray[j + 1];
          TeamArray[j + 1] = tempPRI;
        }
      }
    }

    // Output sorted players
    for (i = 0; i < playerCount; i++)
    {
      PlayerPawn = Pawn(TeamArray[i].Owner);
      
      if (PlayerPawn != None && (PlayerPawn.KillCount + PlayerPawn.DieCount) > 0)
      {
        efficiency = Clamp(int((float(PlayerPawn.KillCount) / float(PlayerPawn.KillCount + PlayerPawn.DieCount)) * 100), 0, 100);
      }
      else
      {
        efficiency = 0;  // No kills/deaths = 0% efficiency
      }
      
      CompleteMessage = CompleteMessage $ " " $ 
                     PostPad(TeamArray[i].PlayerName, maxNameLength, " ") $ 
                     PostPad(" ", 3 - Len(string(int(TeamArray[i].Score))), " ") $ 
                     int(TeamArray[i].Score) $ " " $
                     "(" $ efficiency $ "% Effi)" $ Chr(13) $ Chr(10);
    }

    if (iT < TeamGamePlus(Level.Game).MaxTeams - 1 && teamSize[iT + 1] > 0)
    {
      CompleteMessage = CompleteMessage $ Chr(13) $ Chr(10);
    }
  }

  CompleteMessage = CompleteMessage $ Chr(13) $ Chr(10);
  CompleteMessage = CompleteMessage $ "Best Player is " $ bestPRI.PlayerName $ " with " $ 
                 int(bestPRI.Score) $ " " $ GetFragText(int(bestPRI.Score)) $ "!" $ Chr(13) $ Chr(10);
  CompleteMessage = CompleteMessage $ "```";

  Link.SendText(CompleteMessage);
}

// Override Query Score Function (to broadcast Scoreboard)
function QueryScore(string sNick)
{
  local int i, iT;
  local PlayerReplicationInfo lPRI;
  local int iPingsArray[4], iPLArray[4];

  // Save Ping & PL 4 ScoreBoard
  for (iT = 0; iT < TeamGamePlus(Level.Game).MaxTeams; iT++)
  {
    for (i = 0; i < 32; i++)
    {
      lPRI = TGRI.PRIArray[i];
      if (lPRI == None)
        continue;
      if (!lPRI.bIsSpectator && lPRI.Team == iT)
      {
        iPingsArray[iT] += lPRI.Ping;
        iPLArray[iT] += lPRI.PacketLoss;
      }
    }
  }

  // Spamm out our stuff :)
  Link.SendNotice(sNick, PostPad("Team-Name", 22, " ") $ "|" @ PrePad(sScoreStr, 5, " ") @ "|" @ PrePad("Ping", 4, " ") @ "|" @ PrePad("PL", 4, " ") @ "|" @ PrePad("PPL", 3, " ") @ "|");
  for (iT = 0; iT < TeamGamePlus(Level.Game).MaxTeams; iT++)
  {
    iPingsArray[iT] = iPingsArray[iT] / TeamGamePlus(Level.Game).Teams[iT].Size;
    iPLArray[iT]    = iPLArray[iT]    / TeamGamePlus(Level.Game).Teams[iT].Size;
    Link.SendNotice(sNick, PostPad(conf.sTeams[iT], 20, " ") $ "|" @ PrePad(string(int(TeamGamePlus(Level.Game).Teams[iT].Score)), 5, " ") @ "|" @ PrePad(string(iPingsArray[iT]), 4, " ") @ "|" @ PrePad(string(iPLArray[iT])$"%", 4, " ") @ "|" @ PrePad(TeamGamePlus(Level.Game).Teams[iT].Size, 3, " ") @ "|");
  }
}

// Override QueryPlayers function to provide team based colors
function QueryPlayers(string sNick)
{
  local int iT, iNum, iAll;
  local string sMessage;
  local TournamentPlayer lPlr;
  local PlayerReplicationInfo lPRI;

  Link.SendNotice(sNick, "Player List for" @ Level.Game.GameReplicationInfo.ServerName $ ":");

  iAll = 0;
  for (iT = 0; iT < TeamGamePlus(Level.Game).MaxTeams; iT++)
  {
    iNum = 0;
    sMessage = "";

    foreach AllActors(class'TournamentPlayer', lPlr)
    {
      lPRI = lPlr.PlayerReplicationInfo;
      if (lPRI.Team == iT)
      {
        if (iNum > 0)
          sMessage = sMessage $ ",";
        else
          sMessage = conf.sTeams[iT] $ ":";

        sMessage = sMessage @ bold(lPRI.PlayerName) @ "(" $ string(int(lPRI.Score)) $ ")";

        iNum++;
        iAll++;
      }
    }

    if (iNum > 0)
      Link.SendNotice(sNick, sMessage);
  }

  if (iAll == 0)
    Link.SendNotice(sNick, "No players on server!");
}

defaultproperties
{
  sScoreStr="Frags"
}
