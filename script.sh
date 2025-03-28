#!/bin/bash

# Dependencies: (place the binaries of these next to the script)
# https://github.com/craftablescience/VPKEdit
# https://github.com/StrataSource/vtex2
# https://github.com/pwitvoet/wadmaker

VPK_PATH="full/path/to/pak01_dir.vpk"

echo "Downloading original Narbacular Drop WAD..."
wget https://nuclearmonkeysoftware.com/downloads/narbacular_drop_level_creation_kit.zip
unzip ./narbacular_drop_level_creation_kit.zip -d ./nb_tools
rm -f ./narbacular_drop_level_creation_kit.zip
mv ./nb_tools/WADs/narbaculardrop.wad ./
rm -rf ./nb_tools

# Extract only the assets we might need from the VPK
mkdir -p materials
echo "Extracting materials from VPK..."
mkdir -p materials/anim_wp/framework
./vpkeditcli "$VPK_PATH" -e "/materials/anim_wp/framework/" -o "./materials/anim_wp/framework"
mkdir -p materials/carpet
./vpkeditcli "$VPK_PATH" -e "/materials/carpet/" -o "./materials/carpet"
mkdir -p materials/concrete
./vpkeditcli "$VPK_PATH" -e "/materials/concrete/" -o "./materials/concrete"
mkdir -p materials/de_chateau
./vpkeditcli "$VPK_PATH" -e "/materials/de_chateau/" -o "./materials/de_chateau"
mkdir -p materials/elevator
./vpkeditcli "$VPK_PATH" -e "/materials/elevator/" -o "./materials/elevator"
mkdir -p materials/fabric
./vpkeditcli "$VPK_PATH" -e "/materials/fabric/" -o "./materials/fabric"
mkdir -p materials/glass
./vpkeditcli "$VPK_PATH" -e "/materials/glass/" -o "./materials/glass"
mkdir -p materials/lights
./vpkeditcli "$VPK_PATH" -e "/materials/lights/" -o "./materials/lights"
mkdir -p materials/metal
./vpkeditcli "$VPK_PATH" -e "/materials/metal/" -o "./materials/metal"
mkdir -p materials/moon
./vpkeditcli "$VPK_PATH" -e "/materials/moon/" -o "./materials/moon"
mkdir -p materials/motel
./vpkeditcli "$VPK_PATH" -e "/materials/motel/" -o "./materials/motel"
mkdir -p materials/nature
./vpkeditcli "$VPK_PATH" -e "/materials/nature/" -o "./materials/nature"
mkdir -p materials/plaster
./vpkeditcli "$VPK_PATH" -e "/materials/plaster/" -o "./materials/plaster"
mkdir -p materials/plastic
./vpkeditcli "$VPK_PATH" -e "/materials/plastic/" -o "./materials/plastic"
mkdir -p materials/signage
./vpkeditcli "$VPK_PATH" -e "/materials/signage/" -o "./materials/signage"
mkdir -p materials/tile
./vpkeditcli "$VPK_PATH" -e "/materials/tile/" -o "./materials/tile"
mkdir -p materials/wallpaper
./vpkeditcli "$VPK_PATH" -e "/materials/wallpaper/" -o "./materials/wallpaper"
mkdir -p materials/wood
./vpkeditcli "$VPK_PATH" -e "/materials/wood/" -o "./materials/wood"

# Find textures pointed to by $basetexture keys in VMTs and move those
# textures out into "./textures" with the relative path of the VMT:
find "./materials" -type f -name "*.vmt" | while read -r vmt_file; do
  # Extract the line containing $basetexture (ignoring case and leading whitespace)
  line=$(grep -i '^\s*\$basetexture' "$vmt_file")

  # Proceed only if a basetexture value was found
  if [ ! -n "$line" ]; then
    continue;
  fi

  # Check if the line contains quotes
  if echo "$line" | grep -q '"'; then
    base_texture=$(echo "$line" | sed -E 's/.*"\s*([^"]+)\s*".*/\1/')
  else
    # If not quoted, assume the second field is the value
    base_texture=$(echo "$line" | awk '{print $2}')
  fi

  # Remove CR, replace backslashes with forward slashes, and strip a trailing .vtf extension
  base_texture=$(echo "$base_texture" | tr -d '\r' | sed -E 's/\\/\//g' | sed -E 's/\.vtf$//I')

  # Construct the full path to the source VMF file (append .vmf)
  src_vtf="./materials/${base_texture}.vtf"

  # Convert paths to lowercase
  vmt_file=${vmt_file,,}
  src_vtf=${src_vtf,,}

  # Construct the destination path: keep the relative path of the VMT file,
  # but use its basename (without .vmt) and change extension to .vtf
  relative_dir=$(dirname "$vmt_file")
  vmt_basename=$(basename "$vmt_file" .vmt)
  dest_vtf="./textures/${relative_dir:12}/${vmt_basename}.vtf"

  # Create the destination directory if it doesn't exist
  mkdir -p "$(dirname "$dest_vtf")"

  # Copy the VTF file if it exists
  if [ -f "$src_vtf" ]; then
    cp "$src_vtf" "$dest_vtf"
    echo "Copied $src_vtf to $dest_vtf"
  else
    echo "Source file not found: $src_vtf"
  fi
done

# Remove residual "materials" directory
echo "Cleaning up residual files..."
rm -rf ./materials

# Use vtex2 to extract images from VTFs
echo "Converting VTF to JPEG..."
./vtex2 extract -f jpg -r ./textures

# Rename JPEG files to hashes of their file path
# This is done to compact texture names to 15 characters for the WAD
echo "Hashing JPEG paths..."
mkdir -p "./video"
find "./textures" -type f -iname "*.jpg" | while read -r file; do
  # Generate a hash of the material path and truncate it to 15 characters
  hash=$(echo -n "${file:11:-4}" | md5sum | cut -c1-15)
  # Construct the new path
  new_path="./video/$hash.jpg"
  # Move the file
  mv "$file" "$new_path"
  echo "Moved: $file -> $new_path"
done

# Remove residual "textures" directory
echo "Cleaning up residual files..."
rm -rf ./textures

# Build WAD file with extracted textures
echo "Bundling textures into WAD file..."
# First, move the existing WAD textures into the source directory
./WadMaker -nologfile ./narbaculardrop.wad ./video
# Then, recreate the ND WAD with all textures, old and new
rm -f ./narbaculardrop.wad
./WadMaker -nologfile ./video ./narbaculardrop.wad
# Remove residue WadMaker file
rm -f ./video/wadmaker.dat

# Convert JPEGs to BMPs for use in Narbacular Drop.
# Technically, it's possible to go directly from VTF to BMP,
# but that leads to weird transparent textures and a bulkier WAD (?)
for file in ./video/*.jpg; do
  base_name="${file%.*}"
  convert "$file" "$base_name.bmp"
  rm -f "$file"
  echo "Converted: $file -> $base_name.bmp"
done
