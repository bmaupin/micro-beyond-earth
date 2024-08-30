#!/usr/bin/env bash

mod_name=$(yq -p xml -oy ".Mod.Properties.Name" src/*.modinfo)
mod_version=$(yq -p xml -oy ".Mod.+@version" "src/${mod_name}.modinfo")
mod_name_version="$(echo "${mod_name} (v ${mod_version})")"

echo "Updating mod file checksums ..."
pushd src > /dev/null
# Override IFS (internal field separator) in order to handle files with spaces in name
original_IFS="$IFS"
IFS=$'\n'
for filename in $(find . -type f | cut -c 3-); do
    new_md5sum=$(md5sum "$filename" | awk '{print $1}')
    old_md5sum=$(grep "$filename" "${mod_name}.modinfo" | head -n 1 | awk '{print $2}' | cut -c 6- | rev | cut -c 2- | rev)
    if [[ -n $old_md5sum ]]; then
        sed -i "s@${old_md5sum}\(.*${filename}\)@${new_md5sum}\1@" "${mod_name}.modinfo"
    fi
done
IFS="$original_IFS"
popd > /dev/null

# Clean up previous mod package
rm -f "${mod_name_version}.civbemod"

# Create the mod package
temp_dir=$(mktemp -d -p $(pwd))
cp -ar src/. "${temp_dir}"
pushd "${temp_dir}" > /dev/null
mv "${mod_name}.modinfo" "${mod_name_version}.modinfo"
# Lower-case filenames in the .modinfo file so the entry will match after we lower-case
# the filename in the file system. This is required for Linux Steam workshop compatibility.
sed -i '/<File/s|>\(.*\)<|\L&|' "${mod_name_version}.modinfo"
sed -i '/<UpdateDatabase>/s|>\(.*\)<|\L&|' "${mod_name_version}.modinfo"
sed -i '/<EntryPoint/s|file="\([^"]*\)"|file="\L\1"|' "${mod_name_version}.modinfo"
# Lower-case all file names for cross-platform compatibility, particularly Linux (https://stackoverflow.com/a/152741)
find . -depth -exec rename 's/(.*)\/([^\/]*)/$1\/\L$2/' {} \;
# Delete any previously-created mod packages, otherwise the script will add to them
rm -f ../"$(echo "${mod_name} (v ${mod_version})" | tr '[:upper:]' '[:lower:]').civbemod"
# Write the .civbemod file with a lower-case filename as well. This isn't necessary but
# is more consistent and will make the manual installation instructions less confusing.
7z a -r ../"$(echo "${mod_name} (v ${mod_version})" | tr '[:upper:]' '[:lower:]').civbemod" *
popd > /dev/null
rm -rf "${temp_dir}"
