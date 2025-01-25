class DiscordReporterSpectator extends MessagingSpectator;

var DiscordReporter Controller;
var DiscordReporterLink Link;
var DiscordReporterStats Stats;
var string LastMessage;

// Init Function
function Engage(DiscordReporter InController, DiscordReporterLink InLink)
{
  local Class<DiscordReporterStats> StatsClass;
  local DiscordReporterMutator Mut;
  local Mutator M;
  local string GameClass;

  Controller = InController;
  Link = InLink;

  // 1 on 1 is only applied for DM
  GameClass = caps(GetItemName(string(Level.Game.Class)));
  if (GameClass == "DEATHMATCHPLUS" || GameClass == "EUTDEATHMATCHPLUS")
  {
      StatsClass = class'DiscordReporterStats_DM';
  }
  else if (GameClass == "TEAMGAMEPLUS" || GameClass == "EUTTEAMGAMEPLUS")
  {
    StatsClass = class'DiscordReporterStats_TDM';
  }
  else
    StatsClass = class'DiscordReporterStats_DM';

  Level.Game.BaseMutator.AddMutator(Level.Game.Spawn(class'DiscordReporterMutator'));

  M = Level.Game.BaseMutator;
    while (M != None)
    {
        if (DiscordReporterMutator(M) != None)
        {
            Mut = DiscordReporterMutator(M);
            break;
        }
        M = M.NextMutator;
    }

  // Spawn Actor
  Stats = Spawn(StatsClass);

  // Check if spawn was success
  if (Stats == none)
    Log("++ Unable to spawn Stats Class!");
  else
  {
    Stats.Link = Link;
    Link.Spec = self;

    if (Mut != None)
        {
            Mut.Stats = Stats;
            Mut.conf = Controller.conf;
        }

    Stats.Spec = self;
    Stats.conf = Controller.conf;
    Stats.Level = Level;
    Stats.GRI = Level.Game.GameReplicationInfo;
    Stats.Initialize();
  }
}

function ClientMessage(coerce string S, optional name Type, optional bool bBeep)
{
  if (Type == 'None')
    LastMessage=S;
  if (Stats != None)
    Stats.InClientMessage(S, Type, bBeep);
}

function TeamMessage(PlayerReplicationInfo PRI, coerce string S, name Type, optional bool bBeep)
{
  Stats.InTeamMessage(PRI, S, Type, bBeep);
}

function ReceiveLocalizedMessage(class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
  Stats.InLocalizedMessage(Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}

function ClientVoiceMessage(PlayerReplicationInfo Sender, PlayerReplicationInfo Recipient, name messagetype, byte messageID)
{
  Stats.InVoiceMessage(Sender, Recipient, messagetype, messageID);
}

function string ServerMutate(string MutateString)
{
  local Mutator Mut;
  Mut = Level.Game.BaseMutator;
  Mut.Mutate(MutateString, Self);
  return LastMessage;
}

defaultproperties
{
}
