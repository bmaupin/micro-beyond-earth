# Micro Beyond Earth

💡 [See my other Civ projects here](https://github.com/search?q=user%3Abmaupin+topic%3Acivilization&type=Repositories)

## About

This is a mod to Sid Meier's Civilization: Beyond Earth to allow much shorter games, primarily by shrinking the maps to an extremely small size and also by adding additional game options.

#### Features

- Compatible with Beyond Earth base game and Rising Tide
- Very small maps! Map sizes have been reduced to 9% of their original size (30% of their height and 30% of their width). This alone has the biggest impact on the length of the game. In addition to games being shorter, the game as a whole runs faster as there is less to process (e.g. much less wait time between turns).
- Add ability to disable time victory in game options
- New game option added to disable covert operations. This automatically aborts all covert operations except for Establish Network, making it so that Covert Ops is only about gathering information.
- Shows hidden game options: this allows disabling of some game features (health, virtues, etc.) that could make the game quicker
- Disables buildings and wonders related to hidden game options. For example, if health is disabled then buildings and wonders that only give health (e.g. Pharmalab, Soma Distillery) will not show in the list of available buildings to build.
- New game options to start explorers and workers automated

#### Motivation

The Civilization series is one of my favourite game series, but I don't have the time to play a 10-15 hour game. I tried The Battle of Polytopia (a 4X game designed to be played in less than an hour) but I found it too shallow to be interesting. So instead, I decided to see if I could mod Beyond Earth to make games much shorter, ideally 1-2 hours. This is the result of that experiment.

## Installation

⚠️ If you're playing on Linux, install the patch here to fix the crash when using mods: [https://github.com/bmaupin/civ-be-linux-fixes/](https://github.com/bmaupin/civ-be-linux-fixes/)

Install the mod from Steam here or see below for manual installation instructions:<br>
<a href="https://steamcommunity.com/sharedfiles/filedetails/?id=3309221969">
<img src="steam-store-badge.webp" alt="Available on Steam" width="200px">
</a>

## Usage

1. Start Beyond Earth and go to the _Mods_ menu
1. Check _Micro Beyond Earth_ and any other desired mods
1. Before starting a game, click _Advanced Setup_ to see the new game options mentioned above

#### Additional ways to speed up game play

In the _Advanced Setup_ screen before starting a game, these options can help make the game go faster:

- _Game Pace_ > _Quick_
- _Disable Health_
  - Health as a mechanic was added to prevent "infinite city sprawl," which really isn't an issue with this mod, so it makes more sense to disable it altogether
- _Disable Tutorial Popups_
- _Explorers Start Automated_
  - Saves a click if you typically automate explorers. Can always be cancelled by clicking on the unit > _Stop Automation_.
- _Quick Combat_
- _Quick Movement_
- _Workers Start Automated_
  - Saves a click if you typically automate workers. Can always be cancelled by clicking on the unit > _Stop Automation_.

These are some options that can be changed in-game to make it go faster (go to the menu > _Options_)

- _Advisor Level_ > _No Advice_
- Check _Disable Planetfall Visual Effect_
- Check _Hide Advisor Intro_
- Check _Single Player Auto End Turn_

  ⓘ See _AutoTurnControl_ below for a better alternative to setting Auto End Turn here

## Recommended companion mods

- [AutoTurnControl](https://steamcommunity.com/sharedfiles/filedetails/?id=503856497)
  - Adds a toggle at the top of the screen for toggling Auto End Turn on or off
  - Has additional options that allow toggling Auto End Turn on or off in certain situations

## Known issues

#### Incompatible with Promised Land victory

Because this mod significantly reduces the map sizes, it is likely that the purity affinity victory (Promised Land) will not be possible with the mod because there may not be enough space on the map to settle the new colonists required for the victory.

#### Other missing game features

Again, because the map sizes are so drastically reduced, games will be very different. Depending on which map size is picked and how many other civs there are, some systems may not show up in the game at all, such as:

- Artifacts
- Marvels
- Stations

If you wish to improve your chances of these systems being in the game, try playing on a larger map with fewer civs.

#### Game crashes with `EXCEPTION_ACCESS_VIOLATION`

This error can happen for a number of reasons, not always related to this mod.

If an odd number is used for one of the values of the map size, it will cause the game to crash with this error just before the map is shown. The fix is to only use even numbers. This should be resolved but this note serves as a reminder in case the map sizes are adjusted in the future and this issue happens again.

## Manual installation

#### Linux

Download the repository source file from [Releases](https://github.com/bmaupin/micro-beyond-earth/releases), extract it, and then run the install script:

```
./scripts/install-mod.sh
```

Or:

1. Go to [Releases](https://github.com/bmaupin/micro-beyond-earth/releases) and download the `.civbemod` file
1. Get the version of the mod from [src/Micro Beyond Earth.modinfo](src/Micro%20Beyond%20Earth.modinfo)
   - It's add the end of the `Mod` element, e.g. `version="1"`
1. Create a new directory named `Micro Beyond Earth (v 1)`
   - 👉 Update the value after `(v ` with the version from the previous step
1. Extract the contents of the `.civbemod` file to the directory you created (it's compressed using 7zip)
1. Move the directory to the mods directory
   - Native: ~/.local/share/aspyr-media/Sid Meier's Civilization Beyond Earth/MODS/
   - Proton: ~/.steam/steam/steamapps/compatdata/65980/pfx/drive_c/users/steamuser/Documents/My Games/Sid Meier's Civilization Beyond Earth/MODS

#### Windows

1. Go to [Releases](https://github.com/bmaupin/micro-beyond-earth/releases) and download the `.civbemod` file
1. Copy it to Documents/My Games/Sid Meier's Civilization Beyond Earth/MODS

## Credits

- [Unit Created Event](https://forums.civfanatics.com/resources/unit-created-event-mod-maker-snippet.23175/) from Machiavelli24
