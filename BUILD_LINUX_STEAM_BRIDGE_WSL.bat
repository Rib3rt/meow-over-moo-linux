@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

where wsl >nul 2>nul
if errorlevel 1 goto :missing_wsl

for /f "usebackq delims=" %%I in (`wsl wslpath -a "%SCRIPT_DIR%"`) do set "WSL_SCRIPT_DIR=%%I"
if not defined WSL_SCRIPT_DIR goto :path_error

set "WSL_BUILD_CMD=cd '!WSL_SCRIPT_DIR!/integrations/steam/native' && ./build_linux.sh"
if not "%LUA_INCLUDE_DIR%"=="" set "WSL_BUILD_CMD=cd '!WSL_SCRIPT_DIR!/integrations/steam/native' && LUA_INCLUDE_DIR='%LUA_INCLUDE_DIR%' ./build_linux.sh"
if not "%LUA_CFLAGS%"=="" set "WSL_BUILD_CMD=cd '!WSL_SCRIPT_DIR!/integrations/steam/native' && LUA_CFLAGS='%LUA_CFLAGS%' ./build_linux.sh"

echo Building Linux Steam bridge via WSL...
wsl sh -lc "!WSL_BUILD_CMD!"
if errorlevel 1 goto :build_failed

echo.
echo Linux Steam bridge built successfully:
echo   %SCRIPT_DIR%\integrations\steam\redist\linux64\steam_bridge_native.so
goto :eof

:missing_wsl
echo [ERROR] wsl.exe not found.
echo Install WSL and a Linux distro first.
exit /b 1

:path_error
echo [ERROR] Failed to convert the project path into a WSL path.
exit /b 1

:build_failed
echo [ERROR] Linux Steam bridge build failed in WSL.
echo Ensure WSL has g++, pkg-config, and LuaJIT or Lua 5.1 development headers installed.
exit /b 1
