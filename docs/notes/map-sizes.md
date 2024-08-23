# Map sizes

#### Get maps that have hard-coded sizes

```
$ find . -iname "*.lua" -exec sh -c "grep -H GetMapInitData -A 10 \"{}\" | grep 'GameInfo.Worlds.WORLDSIZE_DU
EL.ID] = {'" \; | sort
./steamassets/assets/dlc/dlc_sp_maps/maps/tiltedaxis.lua-               [GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {52, 32},
./steamassets/assets/dlc/dlc_sp_maps/maps/vulcan.lua-           [GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {28, 20},
./steamassets/assets/dlc/expansion1/maps/ice_age.lua-           [GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {44, 18},
./steamassets/assets/dlc/expansion1/maps/inland_sea.lua-                [GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {28, 18},
./steamassets/assets/dlc/expansion1/maps/skirmish.lua-          [GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {28, 18},
./steamassets/assets/maps/ice_age.lua-          [GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {44, 18},
./steamassets/assets/maps/inland_sea.lua-               [GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {28, 18},
./steamassets/assets/maps/skirmish.lua-         [GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {28, 18},
```

#### Get DLC map names

```
$ egrep -A 1 TXT_KEY_MAP_.+_NAME steamassets/assets/gameplay/xml/text/en_us/civbegametextinfos_dlc.xml
                <Row Tag="TXT_KEY_MAP_VULCAN_NAME">
                        <Text>82 Eridani e</Text>
--
                <Row Tag="TXT_KEY_MAP_ARIDEAN_NAME">
                        <Text>Rigil Khantoris Bb</Text>
--
                <Row Tag="TXT_KEY_MAP_OCEANIA_NAME">
                        <Text>Tau Ceti d</Text>
--
                <Row Tag="TXT_KEY_MAP_TILTED_AXIS_NAME">
                        <Text>Mu Arae f</Text>
--
                <Row Tag="TXT_KEY_MAP_ARBOREAN_NAME">
                        <Text>Kepler 186f</Text>
--
                <Row Tag="TXT_KEY_MAP_WILDERNESS_NAME">
                        <Text>Eta Vulpeculae b</Text>
```

#### Get base game map names

```
$ egrep -v "_HELP|_TITLE|_FORMAT|_OPTION|_SCRIPT|_SIZE|_TYPE|_FOLDER" steamassets/assets/gameplay/xml/text/en
_us/civbegametextinfos_frontendscreens.xml  | grep -A 1 "TXT_KEY_MAP"
    <Row Tag="TXT_KEY_MAP_TERRAN">
      <Text>Terran</Text>
--
    <Row Tag="TXT_KEY_MAP_PROTEAN">
      <Text>Protean</Text>
--
    <Row Tag="TXT_KEY_MAP_ATLANTEAN">
                  <Text>Atlantean</Text>
--
    <Row Tag="TXT_KEY_MAP_TAIGAN">
      <Text>Taigan</Text>
--
    <Row Tag="TXT_KEY_MAP_ARCHIPELAGO">
      <Text>Archipelago</Text>
--
    <Row Tag="TXT_KEY_MAP_TINY_ISLANDS">
      <Text>Tiny Islands</Text>
--
    <Row Tag="TXT_KEY_MAP_SKIRMISH">
      <Text>Skirmish</Text>
--
    <Row Tag="TXT_KEY_MAP_INLAND_SEA">
      <Text>Inland Sea</Text>
--
    <Row Tag="TXT_KEY_MAP_ICE_AGE">
      <Text>Glacial</Text>
--
    <Row Tag="TXT_KEY_MAP_EQUATORIAL">
      <Text>Equatorial</Text>
```
