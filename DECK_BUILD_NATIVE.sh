#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
NATIVE_DIR="$SCRIPT_DIR/integrations/steam/native"
REDIST_DIR="$SCRIPT_DIR/integrations/steam/redist/linux64"
APPIMAGE_DIR="$SCRIPT_DIR/LOVE_11_5_LINUX_RUNTIME_DROP"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERROR] Missing command: $1"
    return 1
  fi
  return 0
}

detect_pkg_config() {
  if command -v pkg-config >/dev/null 2>&1; then
    echo "pkg-config"
    return 0
  fi
  if command -v pkgconf >/dev/null 2>&1; then
    echo "pkgconf"
    return 0
  fi
  return 1
}

find_lua_include_dir() {
  for candidate in \
    /usr/include/luajit-2.1 \
    /usr/local/include/luajit-2.1 \
    /usr/include/luajit-2.0 \
    /usr/local/include/luajit-2.0 \
    /usr/include/lua5.1 \
    /usr/local/include/lua5.1
  do
    if [ -f "$candidate/lua.h" ]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

find_lua_pkg() {
  if "$PKG_CONFIG_BIN" --exists luajit; then
    echo "luajit"
    return 0
  fi
  if "$PKG_CONFIG_BIN" --exists lua5.1; then
    echo "lua5.1"
    return 0
  fi
  return 1
}

need_cmd g++

PKG_CONFIG_BIN="$(detect_pkg_config || true)"

LUA_PKG="$(find_lua_pkg || true)"
LUA_INCLUDE_DIR="$(find_lua_include_dir || true)"

if [ -z "$LUA_PKG" ] && [ -z "$LUA_INCLUDE_DIR" ]; then
  echo "[ERROR] Missing Lua development headers for luajit or lua5.1."
  echo "On Steam Deck Desktop Mode, install them first. Example packages:"
  echo "  sudo steamos-readonly disable"
  echo "  sudo pacman -S --needed base-devel pkgconf luajit"
  exit 1
fi

if [ ! -d "$SCRIPT_DIR/integrations/steam/sdk/public/steam" ]; then
  echo "[ERROR] Steamworks SDK headers missing in integrations/steam/sdk"
  exit 1
fi

if [ ! -f "$APPIMAGE_DIR/love.AppImage" ] \
  && [ ! -f "$APPIMAGE_DIR/love-11.5-x86_64.AppImage" ] \
  && [ ! -f "$APPIMAGE_DIR/love-11.5-linux-x86_64.AppImage" ]; then
  echo "[ERROR] LOVE 11.5 Linux AppImage missing in $APPIMAGE_DIR"
  exit 1
fi

if [ -n "$LUA_PKG" ]; then
  echo "Using Lua pkg-config target: $LUA_PKG"
else
  echo "Using Lua include fallback: $LUA_INCLUDE_DIR"
fi
cd "$NATIVE_DIR"
if [ -n "$LUA_INCLUDE_DIR" ]; then
  LUA_INCLUDE_DIR="$LUA_INCLUDE_DIR" ./build_linux.sh
else
  ./build_linux.sh
fi

echo
echo "Built native bridge:"
echo "  $REDIST_DIR/steam_bridge_native.so"
