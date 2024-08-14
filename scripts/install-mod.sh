#!/usr/bin/env bash

# Update checksums
source "$(dirname "$(which "$0")")/package-mod.sh"

mod_name_version="$(echo "${mod_name} (v ${mod_version})" | tr '[:upper:]' '[:lower:]')"

# Detect whether we're using native or Proton
if [[ -f "/home/$USER/.steam/steam/steamapps/common/Sid Meier's Civilization Beyond Earth/CivBE" ]]; then
    user_directory="/home/${USER}/.local/share/aspyr-media/Sid Meier's Civilization Beyond Earth"
fi

if [[ -f "/home/$USER/.steam/steam/steamapps/common/Sid Meier's Civilization Beyond Earth/CivilizationBE_DX11.exe" ]]; then
    user_directory="/home/${USER}/.steam/steam/steamapps/compatdata/65980/pfx/drive_c/users/steamuser/Documents/My Games/Sid Meier's Civilization Beyond Earth"
fi

echo "Copying mod files ..."
mod_directory="${user_directory}/MODS/${mod_name_version}"

# We have to clean up the mod first because otherwise rename will fail because the files will exist
rm -rf "${mod_directory}"/*
cp -ar src/. "${mod_directory}"
pushd "${mod_directory}" > /dev/null
mv "${mod_name}.modinfo" "${mod_name_version}.modinfo"
# All files have to be renamed to lower-case in Linux for it to work (https://stackoverflow.com/a/152741)
# This isn't needed for Proton but doesn't hurt anything either
find . -depth -exec rename 's/(.*)\/([^\/]*)/$1\/\L$2/' {} \;
popd > /dev/null
