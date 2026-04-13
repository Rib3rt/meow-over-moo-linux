#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
APPIMAGE=""
PKG_CONFIG_BIN=""
LUA_INCLUDE_DIR_HINT=""

find_appimage() {
  for candidate in \
    "$SCRIPT_DIR/LOVE_11_5_LINUX_RUNTIME_DROP/love.AppImage" \
    "$SCRIPT_DIR/LOVE_11_5_LINUX_RUNTIME_DROP/love-11.5-x86_64.AppImage" \
    "$SCRIPT_DIR/LOVE_11_5_LINUX_RUNTIME_DROP/love-11.5-linux-x86_64.AppImage"
  do
    if [ -f "$candidate" ]; then
      APPIMAGE="$candidate"
      return 0
    fi
  done
  return 1
}

detect_pkg_config() {
  if command -v pkg-config >/dev/null 2>&1; then
    PKG_CONFIG_BIN="pkg-config"
    return 0
  fi
  if command -v pkgconf >/dev/null 2>&1; then
    PKG_CONFIG_BIN="pkgconf"
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
      LUA_INCLUDE_DIR_HINT="$candidate"
      return 0
    fi
  done
  return 1
}

have_lua_headers() {
  if [ -n "$PKG_CONFIG_BIN" ]; then
    if "$PKG_CONFIG_BIN" --exists luajit; then
      return 0
    fi
    if "$PKG_CONFIG_BIN" --exists lua5.1; then
      return 0
    fi
  fi
  find_lua_include_dir
}

run_prereq_install() {
  if ! command -v sudo >/dev/null 2>&1 || ! command -v pacman >/dev/null 2>&1; then
    echo "[ERROR] Missing sudo or pacman, so I cannot auto-install Deck prerequisites here."
    return 1
  fi

  echo
  echo "[INFO] Missing Deck build prerequisites. I can install them now."
  printf "Proceed with the one-time Steam Deck setup? [Y/n] "
  read answer
  case "${answer:-Y}" in
    n|N)
      echo
      echo "Okay. When you are ready, run:"
      echo "  sudo steamos-devmode enable || true"
      echo "  sudo steamos-unminimize --dev || true"
      echo "  sudo steamos-readonly disable"
      echo "  sudo pacman-key --init || true"
      echo "  sudo pacman-key --populate archlinux || true"
      echo "  sudo pacman-key --populate holo || true"
      echo "  sudo pacman -Sy --needed archlinux-keyring holo-keyring || sudo pacman -Sy --needed archlinux-keyring"
      echo "  sudo pacman -Syu"
      echo "  sudo pacman -S --needed base-devel pkgconf luajit"
      return 1
      ;;
  esac

  if command -v steamos-devmode >/dev/null 2>&1; then
    sudo steamos-devmode enable || true
  fi
  if command -v steamos-unminimize >/dev/null 2>&1; then
    sudo steamos-unminimize --dev || true
  fi
  if command -v steamos-readonly >/dev/null 2>&1; then
    sudo steamos-readonly disable
  fi
  if command -v pacman-key >/dev/null 2>&1; then
    sudo pacman-key --init || true
    sudo pacman-key --populate archlinux || true
    sudo pacman-key --populate holo || true
  fi
  sudo pacman -Sy --needed archlinux-keyring holo-keyring || sudo pacman -Sy --needed archlinux-keyring
  sudo pacman -Syu
  sudo pacman -S --needed base-devel pkgconf luajit
}

ensure_executables() {
  chmod +x \
    "$SCRIPT_DIR/DECK_BUILD_NATIVE.sh" \
    "$SCRIPT_DIR/DECK_BUILD_AND_PACKAGE.sh" \
    "$SCRIPT_DIR/MAKE_LINUX_PACKAGE.sh" \
    "$SCRIPT_DIR/MAKE_LINUX_PACKAGE_RELEASE.sh" \
    "$SCRIPT_DIR/integrations/steam/native/build_linux.sh" \
    "$APPIMAGE"
}

check_requirements() {
  missing=0

  if ! command -v g++ >/dev/null 2>&1; then
    echo "[ERROR] Missing compiler: g++"
    missing=1
  fi

  detect_pkg_config || true

  if [ "$missing" -eq 0 ] && ! have_lua_headers; then
    echo "[ERROR] Missing Lua development headers for luajit or lua5.1."
    missing=1
  fi

  return "$missing"
}

if [ ! -d "$SCRIPT_DIR/integrations/steam/sdk/public/steam" ]; then
  echo "[ERROR] Steamworks SDK headers missing in:"
  echo "  $SCRIPT_DIR/integrations/steam/sdk/public/steam"
  exit 1
fi

if ! find_appimage; then
  echo "[ERROR] LOVE 11.5 Linux AppImage missing in:"
  echo "  $SCRIPT_DIR/LOVE_11_5_LINUX_RUNTIME_DROP"
  exit 1
fi

ensure_executables

if ! check_requirements; then
  run_prereq_install || exit 1
  if ! check_requirements; then
    echo "[ERROR] Prerequisites are still missing after installation."
    exit 1
  fi
fi

echo "[INFO] Dependencies look good."
echo "[INFO] Using LOVE runtime:"
echo "  $APPIMAGE"
echo
echo "[INFO] Building native Steam bridge..."
"$SCRIPT_DIR/DECK_BUILD_NATIVE.sh"
echo
echo "[INFO] Packaging native Linux build..."
cd "$SCRIPT_DIR"
./MAKE_LINUX_PACKAGE.sh
echo
echo "[OK] Native Linux build and package completed."
