# Steam Integration (Phase 2)

This folder contains the real Steamworks bridge path used by `steam_runtime.lua`.

## Runtime architecture

1. Lua runtime calls `integrations/steam/bridge.lua`.
2. `bridge.lua` tries to load native module `steam_bridge_native`.
3. If native module loads and initializes, all Steam calls are forwarded to it.
4. If native module is missing/fails, bridge degrades safely (offline mode, no crash).

## Native files

- Source:
  - `/Users/mdc/Documents/New project/integrations/steam/native/steam_bridge.hpp`
  - `/Users/mdc/Documents/New project/integrations/steam/native/steam_bridge.cpp`
  - `/Users/mdc/Documents/New project/integrations/steam/native/lua_exports.cpp`
- Build scripts:
  - Linux: `/Users/mdc/Documents/New project/integrations/steam/native/build_linux.sh`
  - Windows: `/Users/mdc/Documents/New project/integrations/steam/native/build_windows.ps1`

## Drop-in layout

- SDK root (headers/libs):
  - `/Users/mdc/Documents/New project/integrations/steam/sdk`
- Redistributables + module output:
  - Linux: `/Users/mdc/Documents/New project/integrations/steam/redist/linux64`
  - Windows: `/Users/mdc/Documents/New project/integrations/steam/redist/win64`

Expected runtime files:

1. Linux:
- `steam_bridge_native.so`
- `libsteam_api.so`

2. Windows:
- `steam_bridge_native.dll`
- `steam_api64.dll`

## Build commands

### Linux

```bash
cd '/Users/mdc/Documents/New project/integrations/steam/native'
./build_linux.sh
```

If Lua include paths are not auto-detected:

```bash
LUA_INCLUDE_DIR=/path/to/lua/includes ./build_linux.sh
```

### Windows (Developer PowerShell)

```powershell
cd 'C:\path\to\New project\integrations\steam\native'
./build_windows.ps1 -LuaIncludeDir 'C:\path\to\lua\include' -LuaLibPath 'C:\path\to\lua\lib'
```

Optional:

```powershell
./build_windows.ps1 -SteamSdkRoot 'C:\path\to\sdk' -OutDir 'C:\path\to\redist\win64' -LuaIncludeDir 'C:\path\to\lua\include' -LuaLibPath 'C:\path\to\lua\lib' -LuaLibName 'lua51.lib'
```

## Exposed bridge functions

The native module exports all methods used by `steam_runtime.lua`, including:

- lifecycle: `init`, `runCallbacks`, `shutdown`
- identity/overlay: `getLocalUserId`, `getPersonaName`, `activateOverlay`
- lobby: `createFriendsLobby`, `joinLobby`, `leaveLobby`, `inviteFriend`, `pollLobbyEvents`, `getLobbySnapshot`, `setLobbyData`, `getLobbyData`, `getSteamIdFromLobbyMember`
- networking: `sendNet`, `pollNet`
- leaderboard: `findOrCreateLeaderboard`, `uploadLeaderboardScore`, `downloadLeaderboardEntriesForUsers`, `downloadLeaderboardAroundUser`

## Notes

- Development AppID is `480`.
- Keep `SETTINGS.STEAM.REQUIRED = false` while validating integration.
- `steam_runtime.lua` normalizes payloads, so Lua game code gets stable tables regardless of bridge internals.
