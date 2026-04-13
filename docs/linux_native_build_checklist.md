# Native Linux / Steam Deck Build Checklist

## Goal
Build a native Linux depot for Steam desktop Linux and Steam Deck without changing the current Windows shipping path.

## Current foundation
- Native Steam bridge source exists in `integrations/steam/native`
- Linux build script exists: `integrations/steam/native/build_linux.sh`
- Linux redist output path exists: `integrations/steam/redist/linux64`
- Linux package builder exists: `scripts/build_native_linux_package.py`
- Linux package entry points:
  - `MAKE_LINUX_PACKAGE.sh`
  - `MAKE_LINUX_PACKAGE_RELEASE.sh`

## Required runtime files
- official LOVE 11.5 Linux AppImage in `LOVE_11_5_LINUX_RUNTIME_DROP`
- built native bridge:
  - `integrations/steam/redist/linux64/steam_bridge_native.so`
  - `integrations/steam/redist/linux64/libsteam_api.so`

## Build steps
1. Build `steam_bridge_native.so` on Linux using `integrations/steam/native/build_linux.sh`
2. Drop the official LOVE 11.5 AppImage into `LOVE_11_5_LINUX_RUNTIME_DROP`
3. Run `./MAKE_LINUX_PACKAGE.sh` for test packages
4. Run `./MAKE_LINUX_PACKAGE_RELEASE.sh` for Steam release packages
5. Upload the extracted `game/` folder contents to the Linux depot

## Validation targets
- native Linux desktop Steam launch
- native Linux overlay
- achievements
- leaderboard
- Steam Input
- Steam Deck native install/launch
- Steam Deck online

## WSL-assisted Windows flow
1. Install WSL with a Linux distro.
2. Install `g++`, `pkg-config`, and LuaJIT or Lua 5.1 development headers inside WSL.
3. From Windows, run `BUILD_LINUX_STEAM_BRIDGE_WSL.bat` to compile `steam_bridge_native.so`.
4. Run `MAKE_LINUX_PACKAGE_WSL.bat` or `MAKE_LINUX_PACKAGE_RELEASE_WSL.bat` to compile and package in one step.

## Steam Deck Desktop Mode quick path
1. Put the project folder on the Deck.
2. Put the official LOVE 11.5 AppImage into `LOVE_11_5_LINUX_RUNTIME_DROP`.
3. Run `./DECK_BUILD_NATIVE.sh` to compile the Linux Steam bridge.
4. Run `./DECK_BUILD_AND_PACKAGE.sh` to compile and package in one step.
5. If Lua headers are missing, install the required packages first.
