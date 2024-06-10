## To do

- [x] Mod map sizes
- [ ] Play with modded map sizes
- [ ] Enable hidden game options
- [ ] Disable buildings and wonders related to hidden game options
- [ ] Update for Rising Tide DLC
- [ ] Give all cities a free Ultrasonic fence?
  - This prevents turns from auto-ending and can slow down the game quite a bit at the beginning. But would it be too big of a negative impact on the game?

## About

#### Features

- Smaller maps: this alone has the biggest impact on the length of the game
- New game option added to disable Covert Ops

## Known issues

#### Incompatible with Promised Land victory

Because this mod significantly reduces the map sizes, it is likely that the purity affinity victory (Promised Land) will not be possible with the mod because there may not be enough space on the map to settle the new colonists required for the victory.

#### Game crashes with `EXCEPTION_ACCESS_VIOLATION`

This seems to happen when an odd number is used for one of the values of the map size. The fix was to only use even numbers. This should be resolved but this note serves as a reminder in case it happens again.
