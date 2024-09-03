# Development

#### Reload mod changes

To reload changes to the mod without exiting Beyond Earth:

1. Make any changes to the mod as needed
1. Delete the mod directory and copy it over again with the new mod content

   ⓘ It's that the mod directory get deleted, otherwise changes won't get picked up. If the mod doesn't show up in the Mods menu, run the command again and it should work. As best as I can tell, the command can be run at any time before the mod is loaded, even in the Mods menu itself.

   e.g.

   ```
   rm -rf ~/.local/share/aspyr-media/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/MODS/micro\ beyond\ earth*; ./scripts/install-mod.sh
   ```

   Or to delete just the current version:

   ```
   rm -rf ~/.local/share/aspyr-media/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/MODS/micro\ beyond\ earth\ \(v\ 6\)/; ./scripts/install-mod.sh
   ```

1. Quit any in-progress games (but not Beyond Earth itself)
1. Go to the _Mods_ menu
1. Check the mod to enable it

   ⓘ The mod should be unchecked to show that it has changed

## Troubleshooting

#### Runtime Error: bad argument #2 to 'lCanAdoptPolicy' (integer expected, got no value)

Errors like these can be caused when calling object functions with `.` (which is supposed to be only used for static functions) instead of `:`, e.g.

```lua
player.CanAdoptPolicy(GameInfo.Policies["POLICY_KNOWLEDGE_1"].ID)
```

instead of

```lua
player:CanAdoptPolicy(GameInfo.Policies["POLICY_KNOWLEDGE_1"].ID)
```
