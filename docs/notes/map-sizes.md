These map scripts have hard-coded sizes:

```
$ find . -iname "*.lua" -exec sh -c "grep -H GetMapInitData -A 5 \"{}\" | grep 'GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {'" \; | sort
./assets/DLC/DLC_SP_Maps/Maps/TiltedAxis.lua-           [GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {52, 32},
./assets/Maps/Ice_Age.lua-              [GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {44, 18},
./assets/Maps/Inland_Sea.lua-           [GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {28, 18},
./assets/Maps/Skirmish.lua-             [GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {28, 18},
```
