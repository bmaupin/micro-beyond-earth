# Development

#### Reload mod changes

To reload changes to the mod without exiting Beyond Earth:

1. Make any changes to the mod as needed
1. If a game is in progress, quit the game (but not Beyond Earth)
1. Go to the _Mods_ menu
1. While in the Mods menu, delete the mod directory and copy it over again with the new mod content

   ⓘ This must be done while in the Mods menu, otherwise changes won't get picked up. It's also important that the mod directory get deleted, otherwise changes won't get picked up.

   e.g.

   ```
   rm -rf ~/.local/share/aspyr-media/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/MODS/micro\ beyond\ earth*; ./scripts/install-mod.sh
   ```
