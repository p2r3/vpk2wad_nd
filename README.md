## Usage instructions
1. This script is written for Bash, so you'll either have to run this on Linux or through WSL.
2. Set the `VPK_PATH` variable to the full path to your Portal 2's `pak01_dir.vpk` file.
3. Fetch these dependencies and put their binaries next to the script:
- [VPKEdit CLI](https://github.com/craftablescience/VPKEdit/releases)
- [vtex2](https://github.com/StrataSource/vtex2/releases)
- [WadMaker](https://github.com/pwitvoet/wadmaker/releases)
4. Run the script: `./script.sh`

## Contributing
I don't see the need for contributions, but if you do, just make sure to not break [vmf2cmf](https://github.com/p2r3/vmf2cmf). That's the parent project of this tool, and the sole reason it exists. That's why this is hardcoded to feature Narbacular Drop textures.
