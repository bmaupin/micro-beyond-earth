# Micro Beyond Earth

📌 [See my other Civ projects here](https://github.com/search?q=user%3Abmaupin+topic%3Acivilization&type=Repositories)

This is a mod to Sid Meier's Civilization: Beyond Earth to allow much shorter games. Features include:

- **Very** small maps (hence the name)
- New game options to allow for faster play
- Victories have been modded for smaller maps and faster play
- Compatible with base game and Rising Tide

See [below](#features) for more information.

## Installation

⚠️ If you're playing on Linux, install the patch here to fix the crash when using mods: [https://github.com/bmaupin/civ-be-linux-fixes/](https://github.com/bmaupin/civ-be-linux-fixes/)

Install the mod from Steam here or see below for manual installation instructions:<br>
<a href="https://steamcommunity.com/sharedfiles/filedetails/?id=3309221969">
<img src="steam-store-badge.webp" alt="Available on Steam" width="200px">
</a>

## Motivation

I don't have time to play a 10-15 hour game of Civilization and short 4X games (Battle of Polytopia) feel too shallow to be interesting. So I made this to try to retain the feel of a Civ game but with a much shorter playtime.

## Usage

1. Start Beyond Earth and go to the _Mods_ menu
1. Check _Micro Beyond Earth_ and any other desired mods
1. Before starting a game, click _Advanced Setup_ to configure additional game options, e.g

   - _Game Pace_ > _Quick_
   - _Auto Upgrade Units_
   - _Disable Covert Operations_
   - _Disable Health_
   - _Disable Tutorial Popups_
   - _Explorers Start Automated_
   - _Quick Combat_
   - _Quick Movement_
   - _Workers Start Automated_

1. After you start the game, go to the menu > _Options_ to see more options that can make the game go faster, e.g.

   - _Advisor Level_ > _No Advice_
   - _Disable Planetfall Visual Effect_
   - _Hide Advisor Intro_
   - _Single Player Auto End Turn_
     - See _AutoTurnControl_ below for a better alternative to this setting

## Recommended companion mods

- [AutoTurnControl](https://steamcommunity.com/sharedfiles/filedetails/?id=503856497)
  - Adds a toggle at the top of the screen for toggling Auto End Turn on or off
  - Has additional options that allow toggling Auto End Turn on or off in certain situations

## Features

#### Very small maps

Map sizes have been reduced to 9% of their original size (30% of their height and 30% of their width). This alone has the biggest impact on the length of the game. In addition to games being shorter, the game as a whole runs faster as there is less to process (e.g. much less wait time between turns).

#### Show hidden game options

The game comes with a handful of options that are hidden by default. They've been made available since several of them in particular can make the game quicker. Here are the options:

- Always Peace
  - Play with this enabled for a quite different game experience
- Always War
  - This effectively disables diplomacy altogether
- Disable Health
  - Health as a mechanic was added to Civ to prevent "infinite city sprawl" which really isn't an issue with this mod, so it makes more sense to disable it altogether
- Disable Research
  - This disables the ability to research any technology and doesn't seem particularly useful
- Disable Tutorial Popups
- Disable Virtues
  - This is one less system to worry about, although it's possible it could make the game actually take longer since it would remove many bonuses that could result in faster play
- Lock Mods
- Permanent War or Peace

#### New game options

New game options have been added to facilitate faster play:

- Auto Upgrade Units
  - This will automatically upgrade units and choose a random perk up to but not including each unit's last upgrade tier; in most cases only the final upgrade tier is significant. **Note** that the auto upgrade happens at the beginning of each turn, so if you get a free affinity in the middle of a turn, the auto upgrade may not happen.
- Disable Covert Operations
  - This automatically aborts all covert operations except for Establish Network, so you can ignore covert ops altogether or use it only to gather information
- Explorers Start Automated
  - Saves a click if you typically automate explorers. Can always be cancelled by clicking on the unit > _Stop Automation_.
- Workers Start Automated
  - Saves a click if you typically automate workers. Can always be cancelled by clicking on the unit > _Stop Automation_.

#### Modified victory conditions

Purity affinity victory (Promised Land) has been modded to automatically summon Earthling settlers and to accommodate smaller map sizes.

Supremacy affinity victory (Emancipation) automatically sends military units at the warp gate at the beginning of each turn.

#### Other features

The time victory condition can be disabled in the game options.

If a previously-hidden game option is checked, buildings and wonders related to that option are disabled. For example, if health is disabled then buildings and wonders that only give health (e.g. Pharmalab, Soma Distillery) will not show in the list of available buildings to build.

Similarly, if Disable Health is checked, health bonuses and maluses are disabled in the game and all players will automatically receive all health-related virtues at the beginning of the game.

## Known issues

#### Game crash or abnormal terrain when loading save second time

The map sizes in this mod are so small that if a save game created with this mod is loaded, subsequent loading of save games (even save games not created with this mod) may cause the game to crash or exhibit terrain abnormalities. While this could potentially be fixed by increasing map sizes, the map sizes are intentionally very small in order to enable finishing the game in just one session, and it's not clear what the exact cause is or if increasing the map sizes would make the issue go away or just make it less frequent.

If the game crashes when loading a save with this mod enabled, simply start the game again and load the save again. As long as the save is only loaded once it shouldn't cause any issues.

The issue appears to occur more frequently with the smaller map sizes such as duel and dwarf, so avoiding those map sizes should reduce chances of encountering this problem.

#### Missing game features

Because the map sizes are so drastically reduced, games will be very different. Depending on which map size is picked and how many other civs there are, some systems may not show up in the game at all, such as:

- Alien nests
- Artifacts
- Marvels
- Stations

If you wish to improve your chances of these systems being in the game, try playing on a larger map with fewer civs.

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

- [Victories - Automated Exodus Gate](https://www.picknmixmods.com/mods/CivBE/Victories/Automated%20Exodus%20Gate.html) from [whoward69](https://forums.civfanatics.com/members/whoward69.210828/)
