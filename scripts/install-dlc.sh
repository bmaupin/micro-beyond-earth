#!/usr/bin/env bash

source "$(dirname "$(which "$0")")/package.sh"

game_directory="/home/${USER}/.steam/steam/steamapps/common/Sid Meier's Civilization Beyond Earth"

# Detect whether we're using native or Proton
if [[ -f "${game_directory}/CivBE" ]]; then
    dlc_directory="${game_directory}/steamassets/assets/dlc/$(echo "${dlc_name}" | tr '[:upper:]' '[:lower:]')"
fi

if [[ -f "${game_directory}/CivilizationBE_DX11.exe" ]]; then
    dlc_directory="${game_directory}/Assets/DLC/${dlc_name}"
fi

# Start with a clean slate every time
rm -rf "${dlc_directory}"
unzip "${dlc_name}.zip" -d "$(dirname "${dlc_directory}")"
