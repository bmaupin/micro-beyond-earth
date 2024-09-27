# Publish to Steam workshop

https://partner.steamgames.com/doc/features/workshop/implementation

#### Instructions

1. Package the content as needed

   - Mod files should not be lower-cased when the mod is published to Steam; this will be done by the mod installer. Lower-casing the mod files ahead of time will result in an md5 error.
   - Mod files should be compressed with 7zip with the extension `.civbemod`

1. Create a preview image

   - This is the image shown on the workshop search page and in the workshop item page
     - This is not the same as the screenshots, which can be added later
   - Existing preview images appear to be square, so this is probably best
   - Steam recommends JPG, PNG and GIF

1. Upload the mod to Steam

   ⓘ It appears that steamcmd's `workshop_build_item` parameter only works with games that use Steam's newer UGC storage. Using it with Beyond Earth will result in an error. steamcmd does have another parameter (`workshop_create_legacy_item`) for older Steam games using the legacy storage (remote storage), however this seems to only work for the initial file upload and not updates.

   1. Download steamremotestorage-uploader

      https://github.com/nnnn20430/steamremotestorage-uploader/releases

   1. Extract steamremotestorage-uploader

      ```
      tar xvf steamremotestorage-uploader-v1.0.tar.xz
      ```

   1. Start Steam

      ⓘ Steam must be running for steamremotestorage-uploader to work

   1. Upload to Steam

      e.g.

      ```
      cd steamremotestorage-uploader/amd64
      ./steamremotestorage-uploader -a 65980 -t "Micro Beyond Earth" -f /path/to/Micro\ Beyond\ Earth\ \(v\ 1\).civbemod -p /path/to/preview.png -n "Initial release"
      ```

1. Later, upload screenshots

   https://steamcommunity.com/sharedfiles/filedetails/?id=2042081690

#### Update an existing mod

e.g.

```
./steamremotestorage-uploader -a 65980 -i 1234567890 -f /path/to/Micro\ Beyond\ Earth\ \(v\ 1\).civbemod -n "New release"
```

## Troubleshooting

#### `Item upload failed: 21`

Updating an existing mod normally goes quickly, but sometimes it takes a while and throws this error. If it happens, close and reopen Steam and try again.

#### Mod doesn't install after uploading it to Steam

Check ~/.local/share/aspyr-media/Sid Meier's Civilization Beyond Earth/Logs/ModInstaller.log
