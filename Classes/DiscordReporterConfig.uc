class DiscordReporterConfig extends Actor;
var string sTeams[4];

var globalconfig bool   bEnabled;
var globalconfig bool   bDebug;
var globalconfig bool   bMuted;
var globalconfig bool   bSilent;
var globalconfig string DiscordBotHost;
var globalconfig int    DiscordBotPort;
var globalconfig string Password;
var globalconfig bool   bAdvertise;
var globalconfig bool   xEnhancedSprees;
var globalconfig bool   xReportSprees;
var globalconfig bool   xReportBSprees;
var globalconfig bool   xReportESprees;
var globalconfig bool   xReportMMI;
var globalconfig string AdMessage;
var globalconfig bool   bExtra1on1Stats;
var globalconfig string teamRed;
var globalconfig string teamBlue;
var globalconfig string teamGreen;
var globalconfig string teamGold;
var globalconfig string colGen;
var globalconfig string colHead;
var globalconfig string colBody;
var globalconfig string colRed;
var globalconfig string colBlue;
var globalconfig string colGreen;
var globalconfig string colGold;
var globalconfig string colHigh;

defaultproperties
{
  bEnabled=True
  DiscordBotHost="192.168.178.12"
  DiscordBotPort=5000
  Password="letmein"
  bSilent=False
  xEnhancedSprees=False
  xReportSprees=True
  xReportBSprees=True
  xReportESprees=True
  xReportMMI=True
  bAdvertise=True
  AdMessage=""
  teamRed="Red Team"
  teamBlue="Blue Team"
  teamGreen="Green Team"
  teamGold="Gold Team"
  colGen="03"
  // colTime="02"
  colHead="02"
  colBody="14"
  colRed="04"
  colBlue="12"
  colGreen="03"
  colGold="07"
  colHigh="04"
}
