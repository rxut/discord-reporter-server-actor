class DiscordReporter extends Actor;

var bool bInitialized;
var DiscordReporterConfig conf;
var DiscordReporterLink Link;
var DiscordReporterSpectator Spectator;
var GameReplicationInfo GRI;

// Event: PreBeginPlay
event PreBeginPlay()
{
  // Check if we're already initialized
  if (bInitialized)
    return;
  bInitialized = TRUE;

  // Load...
  conf = Spawn(class'DiscordReporter.DiscordReporterConfig');
  LoadTeamNames();
  // CheckIRCColors();

  // Start Reporter Engine
  conf.SaveConfig();
  Log("+-----------------------+");
  Log("| Discord Reporter 0.3 |");
  Log("+-----------------------+");
  InitReporter();
}

function InitReporter()
{
  // Start Discord Link
  if (Link == none)
    Link = Spawn(class'DiscordReporter.DiscordReporterLink');

  if (Link == none)
  {
    Log("++ Error Spawning Discord Reporter Link Class!");
    return;
  }

  if (conf.bEnabled)
  {
    Log("++ Starting Connection Process...");
    Link.Connect(self, conf);
  }

  if (Spectator == None)
    Spectator = Level.Spawn(class'DiscordReporter.DiscordReporterSpectator');


  Spectator.Engage(Self, Link);
}

// FUNCTION: Load the Team Names
function LoadTeamNames()
{
  if (Level.Game.GetPropertyText("RedTeamName") != "")
    conf.sTeams[0] = Level.Game.GetPropertyText("RedTeamName");
  else
    conf.sTeams[0] = conf.teamRed;
  if (Level.Game.GetPropertyText("BlueTeamName") != "")
    conf.sTeams[1] = Level.Game.GetPropertyText("BlueTeamName");
  else
    conf.sTeams[1] = conf.teamBlue;
  conf.sTeams[2] = conf.teamGreen;
  conf.sTeams[3] = conf.teamGold;

  conf.SaveConfig();
}

defaultproperties
{
}
