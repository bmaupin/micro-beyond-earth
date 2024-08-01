## To do

- [x] Mod map sizes
- [x] Add option to disable covert operations
- [x] Give all cities a free Ultrasonic fence
- [ ] Package as DLC
  - [ ] Add Lua to DLC config and test
- [x] Play with modded map sizes
- [x] Test with Rising Tide
- [x] Enable hidden game options
- [x] Disable buildings and wonders related to hidden game options
- [ ] Publish to Steam

## About

#### Features

- Smaller maps: this alone has the biggest impact on the length of the game
- Add ability to disable time victory in game options
- New game option added to disable covert operations. This automatically aborts all covert operations except for Establish Network, making it so that Covert Ops is only about gathering information.
- New game option to give all cities a free Ultrasonic Fence. This effectively prevents showing the button that there are aliens that a city can attack, in order to speed up gameplay.
- Shows hidden game options: this allows disabling of some game features (health, virtues, etc.) that could make the game quicker
- Disables buildings and wonders related to hidden game options. For example, if health is disabled then buildings and wonders that only give health (e.g. Pharmalab, Soma Distillery) will not show in the list of available buildings to build.

#### Status

The mod is usable but still undergoing testing. As of this writing, map sizes have been reduced to 9% of their original size (30% of their height and 30% of their width), but this may be adjusted after further testing.

#### Motivation

The Civilization series is one of my favourite game series, but I don't have the time to play a 10-15 hour game. I tried The Battle of Polytopia (a 4X game designed to be played in less than an hour) but I found it too shallow to be interesting. So instead, I decided to see if I could mod Civilization to make games much shorter, ideally 1-2 hours. This is the result of that experiment.

## Known issues

#### Incompatible with Promised Land victory

Because this mod significantly reduces the map sizes, it is likely that the purity affinity victory (Promised Land) will not be possible with the mod because there may not be enough space on the map to settle the new colonists required for the victory.

#### Other missing game features

Again, because the map sizes are so drastically reduced, games will be very different. Depending on which map size is picked and how many other civs there are, some systems may not show up in the game at all, such as:

- Artifacts
- Marvels
- Outposts

If you wish to improve your chances of these systems being in the game, try playing on a larger map with fewer civs.

#### Not all maps are smaller

This mod doesn't make changes to individual maps, only the global map sizes. Maps that override the global map sizes are unaffected by this mod. This includes:

- Ice Age
- Inland Sea
- Skirmish
- Tilted Axis

#### Game crashes with `EXCEPTION_ACCESS_VIOLATION`

This error can happen for a number of reasons, not always related to this mod.

If an odd number is used for one of the values of the map size, it will cause the game to crash with this error just before the map is shown. The fix is to only use even numbers. This should be resolved but this note serves as a reminder in case the map sizes are adjusted in the future and this issue happens again.
