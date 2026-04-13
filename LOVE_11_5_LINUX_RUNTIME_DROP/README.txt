Put the official LOVE 11.5 Linux AppImage in this folder.

Accepted names:
- love.AppImage
- love-11.5-x86_64.AppImage
- love-11.5-linux-x86_64.AppImage
- or any single *.AppImage file

Recommended source:
- official LOVE Linux AppImage from the LOVE release/download page

Workflow:
1. Build the native Steam bridge first so these files exist:
   integrations/steam/redist/linux64/steam_bridge_native.so
   integrations/steam/redist/linux64/libsteam_api.so
2. Drop the LOVE AppImage here.
3. Run:
   ./MAKE_LINUX_PACKAGE.sh

For Steam release packaging:
- use ./MAKE_LINUX_PACKAGE_RELEASE.sh
- upload the extracted contents of the generated game/ folder as the Linux depot root
- do not upload a zip as the SteamPipe content root

Windows packaging wrapper:
- MAKE_LINUX_PACKAGE.bat
- MAKE_LINUX_PACKAGE_RELEASE.bat

These batch files package a native Linux depot on Windows only if the Linux AppImage and prebuilt linux64 Steam bridge files are already present. They do not compile steam_bridge_native.so on Windows.

WSL-assisted workflow on Windows:
- BUILD_LINUX_STEAM_BRIDGE_WSL.bat
- MAKE_LINUX_PACKAGE_WSL.bat
- MAKE_LINUX_PACKAGE_RELEASE_WSL.bat

These wrappers use WSL to compile steam_bridge_native.so, then return to Windows Python packaging.
WSL must have: g++, pkg-config, and LuaJIT or Lua 5.1 development headers installed.

Deck helpers:
- ./DECK_BUILD_NATIVE.sh
- ./DECK_BUILD_AND_PACKAGE.sh
