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

- (In progress) Smaller maps: this alone has the biggest impact on the length of the game
- Add ability to disable time victory in game options
- New game option added to disable covert operations. This automatically aborts all covert operations except for Establish Network, making it so that Covert Ops is only about gathering information.
- New game option to give all cities a free Ultrasonic Fence. This effectively prevents showing the button that there are aliens that a city can attack, in order to speed up gameplay.

## Known issues

#### Incompatible with Promised Land victory

Because this mod significantly reduces the map sizes, it is likely that the purity affinity victory (Promised Land) will not be possible with the mod because there may not be enough space on the map to settle the new colonists required for the victory.

#### Game crashes with `EXCEPTION_ACCESS_VIOLATION`

This error can happen for a number of reasons, not always related to this mod.

If an odd number is used for one of the values of the map size, it will cause the game to crash with this error just before the map is shown. The fix is to only use even numbers. This should be resolved but this note serves as a reminder in case the map sizes are adjusted in the future and this issue happens again.
