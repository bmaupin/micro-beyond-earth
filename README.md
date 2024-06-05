## To do

- [x] Mod map sizes
- [ ] Fix issue with crashing due to map sizes
  - [ ] Test with staggered starts disabled
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

TODO: what is the cause? what is the solution?

This may happen when starting a new game or loading a saved game. I'm not completely sure why this happens but my guess is that it happens when the map is too small for the number of Civs that are supposed to be on the map.

If it happens when loading a saved game, I don't think there's a solution.

If it happens when starting a new game, try reducing the number of players on the map, or lower the sea level to increase the amount of available space

Testing:

- Atlantean, default Civs, medium sea level
  - Duel (2): +
  - Dwarf (4): +
  - Small (6): crash
- Atlantean, small, medium sea level
  - 2 Civs: works
  - 3 Civs: crash

Last logs in Lua.log when crashing:

```
[17648.273] Map Script: Map Generation - Adding Artifacts
...
[17648.295] Map Script: Determining continents for art purposes (MapGenerator.Lua)
```

When not crashing:

```
[17586.129] Map Script: Determining continents for art purposes (MapGenerator.Lua)
[17588.193] CivilopediaScreen: Assets\UI\Civilopedia\CivilopediaScreen.lua:1141:  Cannot find key - DecorationOnly
```

Modding map sizes with Atlantean map and default Civs:

- Small: 26x18 (instead of 26x17): good
  - 26x16: good
- Standard: 32x22 (instead of 32x21): good
  - 32x20: good
