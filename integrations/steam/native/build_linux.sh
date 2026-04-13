#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

STEAM_SDK_ROOT="${STEAM_SDK_ROOT:-$PROJECT_ROOT/integrations/steam/sdk}"
STEAM_REDIST_ROOT="${STEAM_REDIST_ROOT:-$PROJECT_ROOT/integrations/steam/redist/linux64}"

mkdir -p "$STEAM_REDIST_ROOT"

if [[ ! -d "$STEAM_SDK_ROOT/public/steam" ]]; then
    echo "Steamworks headers not found at: $STEAM_SDK_ROOT/public/steam"
    echo "Set STEAM_SDK_ROOT or drop SDK into integrations/steam/sdk"
    exit 1
fi

find_lua_include_dir() {
    for candidate in \
        /usr/include/luajit-2.1 \
        /usr/local/include/luajit-2.1 \
        /usr/include/luajit-2.0 \
        /usr/local/include/luajit-2.0 \
        /usr/include/lua5.1 \
        /usr/local/include/lua5.1
    do
        if [[ -f "$candidate/lua.h" ]]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

PKG_CONFIG_BIN="${PKG_CONFIG_BIN:-}"
if [[ -z "$PKG_CONFIG_BIN" ]]; then
    if command -v pkg-config >/dev/null 2>&1; then
        PKG_CONFIG_BIN="pkg-config"
    elif command -v pkgconf >/dev/null 2>&1; then
        PKG_CONFIG_BIN="pkgconf"
    fi
fi

LUA_CFLAGS="${LUA_CFLAGS:-}"
if [[ -z "$LUA_CFLAGS" && -n "$PKG_CONFIG_BIN" ]]; then
    LUA_CFLAGS="$($PKG_CONFIG_BIN --cflags luajit 2>/dev/null || $PKG_CONFIG_BIN --cflags lua5.1 2>/dev/null || true)"
fi

if [[ -z "$LUA_CFLAGS" && -n "${LUA_INCLUDE_DIR:-}" ]]; then
    LUA_CFLAGS="-I${LUA_INCLUDE_DIR}"
fi

if [[ -z "$LUA_CFLAGS" ]]; then
    LUA_INCLUDE_DIR="$(find_lua_include_dir || true)"
    if [[ -n "$LUA_INCLUDE_DIR" ]]; then
        LUA_CFLAGS="-I${LUA_INCLUDE_DIR}"
    fi
fi

if [[ -z "$LUA_CFLAGS" ]]; then
    echo "Could not resolve Lua include flags. Set LUA_CFLAGS or LUA_INCLUDE_DIR."
    exit 1
fi

OUTPUT_MODULE="$STEAM_REDIST_ROOT/steam_bridge_native.so"
STEAM_API_LIB=""
for candidate in     "$STEAM_SDK_ROOT/redistributable_bin/linux64/libsteam_api.so"     "$STEAM_REDIST_ROOT/libsteam_api.so"
do
    if [[ -f "$candidate" ]]; then
        STEAM_API_LIB="$candidate"
        break
    fi
done

if [[ -z "$STEAM_API_LIB" ]]; then
    echo "Could not find libsteam_api.so in Steam SDK or linux64 redist path."
    echo "Checked:"
    echo "  $STEAM_SDK_ROOT/redistributable_bin/linux64/libsteam_api.so"
    echo "  $STEAM_REDIST_ROOT/libsteam_api.so"
    exit 1
fi

g++ -std=c++17 -O2 -fPIC -shared     "$SCRIPT_DIR/steam_bridge.cpp"     "$SCRIPT_DIR/lua_exports.cpp"     -I"$STEAM_SDK_ROOT/public"     $LUA_CFLAGS     "$STEAM_API_LIB"     -Wl,-rpath,'$ORIGIN'     -o "$OUTPUT_MODULE"

if [[ "$STEAM_API_LIB" != "$STEAM_REDIST_ROOT/libsteam_api.so" ]]; then
    cp "$STEAM_API_LIB" "$STEAM_REDIST_ROOT/libsteam_api.so"
fi

echo "Built: $OUTPUT_MODULE"
