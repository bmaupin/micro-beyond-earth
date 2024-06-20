#!/usr/bin/env bash

source "$(dirname "$(which "$0")")/package.sh"

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
7z x "${mod_name_version}.civbemod" -o"${mod_directory}"
