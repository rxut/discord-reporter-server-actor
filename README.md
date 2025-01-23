# Discord Live Reporter Actor for UT99

This is an Unreal Tournament 99 Server Actor. It sends messages from the game to a [Discord](https://discordapp.com) bot. This is where [discord-reporter](https://github.com/rxut/discord-live-reporter) comes into play, a Discord bot that relays the messages to the Discord server and channel of your choice.

Please note that you need [discord-reporter](https://github.com/rxut/discord-live-reporter) (Node.js Discord bot) to make commucation between the UT99 server and Discord possible.

This is very WIP and far from finished, so use at your own risk.

I've made edits to improve the formatting and how the messages are sent to Discord.

This version of the actor only supports TDM and DM. The original from sn3p had CTF built-in so you can use that if you need CTF, DOM or LMS.

## Installation

1. Add the mutator's class to the ServerActors (not ServerPackages!) list in the `[Engine.GameEngine]` section in server UnrealTournament.ini (or whatever ini file you/your host has). This should go after or at the end of the list of server ServerActors:

```ini
ServerActors=DiscordReporter.DiscordReporter
```

2. Copy the contents of the "System" directory to the "System" directory on your UT Server.  
(Do not upload the system folder INTO the system folder, only the contents!) (`*.u|*.int`).

3. You'll need [discord-reporter](https://github.com/rxut/discord-live-reporter) to relay the messages to Discord.


## Configuration

The configuration is stored in your UnrealTournament.ini file. Most of the options can be found in the section `[DiscordReporter.DiscordReporterConfig]`.

Here's an example

```ini
[DiscordReporter.DiscordReporterConfig]
bEnabled=True
bDebug=False
bMuted=False
bSilent=False
DiscordBotHost=145.145.144.144
DiscordBotPort=5000
Password=password
xSDetailsDelay=120
bAdvertise=False
xEnhancedSprees=False
xReportSprees=True
xReportBSprees=True
xReportESprees=True
xReportMMI=True
xDefaultKills=True
AdMessage=
bExtra1on1Stats=True
teamRed=Red Team
teamBlue=Blue Team
teamGreen=Green Team
teamGold=Gold Team
```

## Credits

The original version was built by sn3p https://github.com/sn3p/DiscordReporter based on the MvReporter for IRC.