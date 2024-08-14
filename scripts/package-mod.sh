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
        # -r allows references like \1 to be used without escaping parenthesis
        sed -i -r "s@${old_md5sum}(.*${filename})@${new_md5sum}\1@" "${mod_name}.modinfo"
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
7z a -r ../"${mod_name_version}.civbemod" *
popd > /dev/null
rm -rf "${temp_dir}"
