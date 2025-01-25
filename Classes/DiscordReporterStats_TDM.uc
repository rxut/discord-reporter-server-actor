class DiscordReporterStats_TDM extends DiscordReporterStats_DM;

var string sScoreStr;

// Maximum size for a single message chunk
const MAX_CHUNK_SIZE = 300;

// Maximum size for the complete message including wrapper
const MAX_TOTAL_SIZE = 450;

// Minimum content size to allow
const MIN_CHUNK_SIZE = 50;

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

// Escape JSON string
function string EscapeJSON(string str)
{
    local string result;
    local int i, len;
    local string ch;
    local int charCode;
    
    len = Len(str);
    for (i = 0; i < len; i++)
    {
        ch = Mid(str, i, 1);
        charCode = Asc(ch);
        
        // Handle common escape sequences
        if (ch == "\"")
            result = result $ "\\\"";
        else if (ch == "\\")
            result = result $ "\\\\";
        else if (ch == Chr(8))
            result = result $ "\\b";
        else if (ch == Chr(12))
            result = result $ "\\f";
        else if (ch == Chr(10))
            result = result $ "\\n";
        else if (ch == Chr(13))
            result = result $ "\\r";
        else if (ch == Chr(9))
            result = result $ "\\t";
        // Handle control characters and non-printable ASCII
        else if (charCode < 32 || charCode > 126)
            result = result $ "\\u" $ PrePad(ToHex(charCode), 4, "0");
        else
            result = result $ ch;
    }
    return result;
}

// Helper function to convert number to hex
function string ToHex(int num)
{
    local string hex;
    local int digit;
    local string hexChars;
    
    hexChars = "0123456789ABCDEF";
    
    while (num > 0)
    {
        digit = num % 16;
        hex = Mid(hexChars, digit, 1) $ hex;
        num = num / 16;
    }
    
    return hex;
}

// Split and send a large message in chunks
function SendSplitMessage(string Message)
{
    local int i, len, chunks, remaining, chunkSize, startPos;
    local string chunk, splitMsg, completeMsg;
    local bool foundSplit;
    local int searchWindow;
    local int wrapperOverhead;
    local string prefix;
    
    prefix = "SPLIT_MSG:";
    len = Len(Message);
    chunks = (len + MAX_CHUNK_SIZE - 1) / MAX_CHUNK_SIZE;  // Ceiling division
    remaining = len;
    startPos = 0;
    
    for (i = 0; i < chunks; i++)
    {
        // Calculate initial chunk size
        chunkSize = Min(remaining, MAX_CHUNK_SIZE);
        
        // Calculate wrapper overhead for this chunk
        wrapperOverhead = Len(prefix) + Len("{\"chunk\":,\"total\":,\"data\":\"\"}") + 
                         Len(string(i + 1)) + Len(string(chunks)) + 4;  // +4 for CRLF CRLF
        
        // Adjust chunk size to account for wrapper overhead and escaping
        chunkSize = Min(chunkSize, MAX_TOTAL_SIZE - wrapperOverhead - 50);  // -50 for escape character overhead
        
        // Extract chunk
        chunk = Mid(Message, startPos, chunkSize);
        
        // If not the last chunk, try to find a good split point
        if (i < chunks - 1 && chunkSize > MIN_CHUNK_SIZE)
        {
            foundSplit = false;
            searchWindow = Min(50, chunkSize - MIN_CHUNK_SIZE); // Don't search past minimum size
            
            while (!foundSplit && searchWindow < chunkSize - MIN_CHUNK_SIZE)
            {
                // Try to find various safe split points
                if (Mid(chunk, chunkSize - searchWindow - 1, 2) == "},")
                {
                    chunkSize = chunkSize - searchWindow;
                    foundSplit = true;
                }
                else if (Mid(chunk, chunkSize - searchWindow - 1, 2) == "\",")
                {
                    chunkSize = chunkSize - searchWindow;
                    foundSplit = true;
                }
                searchWindow++;
            }
            
            // If we couldn't find a good split point, force a split at a safe size
            if (!foundSplit)
            {
                chunkSize = Max(MIN_CHUNK_SIZE, chunkSize - 100);
            }
            
            chunk = Mid(Message, startPos, chunkSize);
        }
        
        // Don't send empty chunks
        if (Len(chunk) > 0)
        {
            // Create split message wrapper
            splitMsg = "{\"chunk\":" $ (i + 1) $ 
                      ",\"total\":" $ chunks $ 
                      ",\"data\":\"" $ EscapeJSON(chunk) $ "\"}";
            
            // Build complete message with prefix
            completeMsg = prefix $ splitMsg;
            
            // Final size check
            if (Len(completeMsg) + 4 <= MAX_TOTAL_SIZE)  // +4 for CRLF CRLF
            {
                // Send complete message with separators
                Link.SendText(completeMsg $ Chr(13) $ Chr(10) $ Chr(13) $ Chr(10));
            }
            else
            {
                // If somehow still too large, send error and abort
                Link.SendText("ERROR: Chunk size exceeded limit" $ Chr(13) $ Chr(10));
                return;
            }
        }
        
        // Update position and remaining length
        startPos += chunkSize;
        remaining -= chunkSize;
        
        // Recalculate chunks if needed
        if (remaining > 0)
        {
            chunks = Max(chunks, i + 1 + (remaining + MAX_CHUNK_SIZE - 1) / MAX_CHUNK_SIZE);
        }
    }
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
  local PlayerReplicationInfo TeamArray[32];
  local string JsonMessage;
  local string sTimeMsg;
  local int totalPlayers;
  local int teamSize[4];
  local bool bHasRedTeam;
  // First pass - collect all players
  totalPlayers = 0;
  
  for (i = 0; i < 32; i++)
  {
    lPRI = TGRI.PRIArray[i];
    if (lPRI != None && !lPRI.bIsSpectator)
    {
      totalPlayers++;
      teamSize[lPRI.Team]++;
      
      if (bestPRI == None || bestPRI.Score < lPRI.Score)
        bestPRI = lPRI;
    }
  }

  // Build time message
  if (TGRI.TimeLimit > 0)
  {
    if (int(TGRI.RemainingTime) == (TGRI.TimeLimit * 60))
      sTimeMsg = "Waiting For Start";
    else
      sTimeMsg = GetStrTime(TGRI.RemainingTime);
  }
  else
    sTimeMsg = "No Time Limit - Score Limit: " $ TGRI.FragLimit;

  // Start JSON message
  JsonMessage = "GAME_STATUS:{";
  
  // Add server info
  JsonMessage = JsonMessage $ 
    "\"serverName\":\"" $ EscapeJSON(Level.Game.GameReplicationInfo.ServerName) $ "\"," $
    "\"gameMode\":\"" $ EscapeJSON(Level.Game.GameName) $ "\"," $
    "\"map\":\"" $ EscapeJSON(Level.Title) $ "\"," $
    "\"timeRemaining\":\"" $ EscapeJSON(sTimeMsg) $ "\",";

  // Add teams
  
  bHasRedTeam = false;
  
  for (iT = 0; iT < TeamGamePlus(Level.Game).MaxTeams; iT++)
  {
    if (teamSize[iT] == 0)
      continue;

    // Add comma if we already added a team
    if (bHasRedTeam)
      JsonMessage = JsonMessage $ ",";

    // Start team section
    if (iT == 0)
    {
      JsonMessage = JsonMessage $ "\"redTeam\":{";
      bHasRedTeam = true;
    }
    else if (iT == 1)
      JsonMessage = JsonMessage $ "\"blueTeam\":{";
    else
      continue;  // Skip other teams for now

    JsonMessage = JsonMessage $ "\"score\":\"" $ int(TeamGamePlus(Level.Game).Teams[iT].Score) $ "\",\"players\":[";

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

    // Add players to JSON
    for (i = 0; i < playerCount; i++)
    {
      PlayerPawn = Pawn(TeamArray[i].Owner);
      
      if (PlayerPawn != None && (PlayerPawn.KillCount + PlayerPawn.DieCount) > 0)
        efficiency = Clamp(int((float(PlayerPawn.KillCount) / float(PlayerPawn.KillCount + PlayerPawn.DieCount)) * 100), 0, 100);
      else
        efficiency = 0;

      // Add player info
      JsonMessage = JsonMessage $ "{";
      JsonMessage = JsonMessage $ "\"name\":\"" $ EscapeJSON(TeamArray[i].PlayerName) $ "\",";
      JsonMessage = JsonMessage $ "\"score\":\"**" $ int(TeamArray[i].Score) $ "**\",";
      JsonMessage = JsonMessage $ "\"efficiency\":\"" $ efficiency $ "\"";
      JsonMessage = JsonMessage $ "}";
      
      if (i < playerCount - 1)
        JsonMessage = JsonMessage $ ",";
    }

    JsonMessage = JsonMessage $ "]}";
    
    // Add spacing between teams if this is the red team
    if (iT == 0)
      JsonMessage = JsonMessage $ ",\"spacing\":\"\\n\\n\"";
  }

  // Add spectators
  JsonMessage = JsonMessage $ ",\"spectators\":[";
  j = 0;
  for (i = 0; i < 32; i++)
  {
    lPRI = TGRI.PRIArray[i];
    // Only count spectators with ping > 0 (actually connected)
    if (lPRI != None && lPRI.bIsSpectator && lPRI.Ping > 0)
    {
      if (j > 0)
        JsonMessage = JsonMessage $ ",";
      JsonMessage = JsonMessage $ "{\"name\":\"" $ EscapeJSON(lPRI.PlayerName) $ "\"}";
      j++;
    }
  }
  JsonMessage = JsonMessage $ "]";

  // Add server IP - use GetAddressString() for proper IP:Port format
  JsonMessage = JsonMessage $ ",\"serverIP\":\"unreal://" $ Level.GetAddressURL() $ "\"";
  
  // Close JSON
  JsonMessage = JsonMessage $ "}";

  // Send the JSON message
  SendSplitMessage(JsonMessage);
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
