## To do

- [x] Mod map sizes
- [ ] Play with modded map sizes
- [ ] Enable hidden game options
- [ ] Disable buildings and wonders related to hidden game options
- [ ] Update for Rising Tide DLC
- [ ] Give all cities a free Ultrasonic fence?
  - This prevents turns from auto-ending and can slow down the game quite a bit at the beginning. But would it be too big of a negative impact on the game?

## Research

- [ ] Way to disable espionage?
  - ~~Try to add `GAMEOPTION_NO_ESPIONAGE` game option~~
    - This only showed up in one of the files of the Linux build, probably some leftover artifact of Civ 5
  - Add a new game option?
    - Add a new game option (e.g. `GAMEOPTION_NO_ESPIONAGE`), then with Lua disable techs related to espionage (which should also cover units, buildings, wonders)
      - Use `FLAVOR_ESPIONAGE`?
