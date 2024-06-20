# DLC

#### Prerequisites

1. List dependencies

   ```
   ldd CivBE
   ```

1. Install missing dependencies as needed, e.g.

   ```
   cp ~/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/i386-linux-gnu/libopenal.so.1 .
   cp ~/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/i386-linux-gnu/libtbb.so.2 .
   ```

   ⚠️ Don't install dependencies via the system package manager. In particular, Ubuntu's `libtbb2:i386` seems to make the game crash, typically in less than ten turns.

#### Setup

1. Create new directory in assets/dlc

   - Valid characters: a-z, A-Z, `_`

1. Create `.CivBEPkg` file in DLC directory

   - Give it the same name as the directory
   - Look inside another DLC directory for an example

1. In the `.CivBEPkg` file, it should have at a minimum:

   - `GUID`: must contain a unique UUID; can be the same as the mod
   - `SteamApp`: must be present but can have any value, including no value
   - `Version`: must not be empty
   - `Key`: must be present but can have any value (while the key is being generated)

   ⚠️ If `GUID`, `SteamApp` or `Version` change, the key must be regenerated

1. Copy Lua and XML files to the DLC directory as needed and make sure to add them to the `.CivBEPkg` file

#### Generate key

1. Start steam from a terminal

   ```
   steam
   ```

1. Create

   ```
   echo 65980 > steam_appid.txt
   ```

1. Generate key

   ```
   timeout -s HUP 3 ./CivBE 2>&1 | grep GUID
   ```
