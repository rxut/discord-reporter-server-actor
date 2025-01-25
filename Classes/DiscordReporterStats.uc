class DiscordReporterStats extends UBrowserBufferedTCPLink;
// Switched class due to error.
// class DiscordReporterStats extends Actor;

var DiscordReporterLink Link;
var DiscordReporterSpectator Spec;
var DiscordReporterConfig conf;

var LevelInfo Level;
var GameReplicationInfo GRI;

var string ircBold;
var string ircColor;
var string ircUnderline;
var bool bBTScores;

// Initialization Function
function Initialize()
{
  if ((Left(string(Level), 3)=="BT-" || Left(string(Level), 5)=="CTF-BT-") && string(Level.Game.class)!="BotPack.CTFGame")
    bBTScores=True;
  Log("++ Stats Actor Initialized!");
}

// Recieve General Messages (Joins, Parts, etc)
function InClientMessage(coerce string S, optional name Type, optional bool bBeep)
{
}

function SendMessage(string msg, optional bool bNoTime)
{
    local string Message;

    // Check is null or blank
    if (msg == "")
        return;

    // Check if EUT MMI's are in the message
    if (conf.xReportMMI == False)
    {
        if (InStr(Caps(msg), Caps("[MMI]")) != -1)
        {
            if (Mid(msg, 5, 2) == "[]")
                return;
        }
    }

    // Format Message
    Message = msg;

    // Send the message
    if (Link != None)
        Link.SendText(Message $ Chr(13) $ Chr(10));
}

// Recieve Say Messages
function InTeamMessage(PlayerReplicationInfo PRI, coerce string S, name Type, optional bool bBeep)
{
}

// Recieve Localized Messages
function InLocalizedMessage(class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
}

// Recieve Taunts
function InVoiceMessage(PlayerReplicationInfo Sender, PlayerReplicationInfo Recipient, name messagetype, byte messageID)
{
}

static function string PrePad(coerce string S, int Size, string Pad)
{
  if (Len(S) > Size)
    return Left(S, Size-3)$"...";
  while (Len(S) < Size)
    S = Pad $ S;
  return S;
}

static function string PostPad(coerce string S, int Size, string Pad)
{
  if (Len(S) > Size)
    return Left(S, Size-3)$"...";
  while (Len(S) < Size)
    S = S $ Pad;
  return S;
}

function string GetStrTime(int Time)
{
  local int m;
  local int s;
  // local string str;

  m = (Time % 3600) / 60;
  s = Time % 60;
  return PrePad(string(m),2,"0") $ ":" $ PrePad(string(s),2,"0");
}

function String GetClientVoiceMessageString(PlayerReplicationInfo Sender, PlayerReplicationInfo Recipient, name messagetype, byte messageID)
{
  local VoicePack V;
  local String sStr;

  if ((Sender == None) || (Sender.voicetype == None))
    return "";

  V = Spawn(Sender.voicetype, self);
  if (V == none)
    return "";

  if (messagetype == 'ACK')
    sStr = sStr $ ChallengeVoicePack(V).static.GetAckString(messageID);
  else
  {
    if (recipient != none)
    {
      sStr = sStr $ ChallengeVoicePack(V).GetCallSign(Recipient);
    }
    if (messagetype == 'FRIENDLYFIRE')
    {
      sStr = sStr $ ChallengeVoicePack(V).static.GetFFireString(messageID);
    }
    else if (messagetype == 'TAUNT')
    {
      sStr = sStr $ ChallengeVoicePack(V).static.GetTauntString(messageID);
    }
    else if (messagetype == 'AUTOTAUNT')
    {
      sStr = sStr $ ChallengeVoicePack(V).static.GetTauntString(messageID);
      sStr = "";
    }
    else if (messagetype == 'ORDER')
    {
      sStr = sStr $ ChallengeVoicePack(V).static.GetOrderString(messageID, "Deathmatch");
    }
    else
    {
      sStr = sStr $ ChallengeVoicePack(V).static.GetOtherString(messageID);
    }
  }

  V.Destroy();
  return sStr;
}

// Message formatting
function string bold(string s)
{
    return "**" $ s $ "**";
}

static function string italic(string s)
{
    return "*" $ s $ "*";
}

// IRC Queries
function QueryMap(string sNick)
{
}
function QueryInfo(string sNick)
{
}
function QuerySpecs(string sNick)
{
}
function QueryPlayers(string sNick)
{
}
function QueryScore(string sNick)
{
}

defaultproperties
{
  ircBold="**"
  ircColor=""
  ircUnderline="*"
}
