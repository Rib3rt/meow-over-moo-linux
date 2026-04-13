@echo off
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "PY_CMD=py -3"
where py >nul 2>nul
if errorlevel 1 set "PY_CMD=python"

set "APPIMAGE_DIR=%SCRIPT_DIR%\LOVE_11_5_LINUX_RUNTIME_DROP"
set "APPIMAGE_OK="
for %%F in (love.AppImage love-11.5-x86_64.AppImage love-11.5-linux-x86_64.AppImage) do (
  if exist "%APPIMAGE_DIR%\%%F" set "APPIMAGE_OK=1"
)
if not defined APPIMAGE_OK (
  for %%F in ("%APPIMAGE_DIR%\*.AppImage") do set "APPIMAGE_OK=1"
)
if not defined APPIMAGE_OK goto :missing_appimage

if not exist "%SCRIPT_DIR%\integrations\steam\redist\linux64\steam_bridge_native.so" goto :missing_bridge
if not exist "%SCRIPT_DIR%\integrations\steam\redist\linux64\libsteam_api.so" goto :missing_steamapi

%PY_CMD% "%SCRIPT_DIR%\scripts\build_native_linux_package.py" --source-project "%SCRIPT_DIR%" --linux-runtime-dir "%APPIMAGE_DIR%" --output-parent "%SCRIPT_DIR%\.."
if errorlevel 1 goto :build_failed

echo.
echo Linux native package build completed.
echo Check the generated MeowOverMoo_LinuxNative_LinuxPackage_* folder beside this project.
goto :eof

:missing_appimage
echo [ERROR] Missing LOVE 11.5 Linux AppImage in:
echo   %APPIMAGE_DIR%
echo Accepted names:
echo   love.AppImage
echo   love-11.5-x86_64.AppImage
echo   love-11.5-linux-x86_64.AppImage
exit /b 1

:missing_bridge
echo [ERROR] Missing Linux Steam bridge:
echo   %SCRIPT_DIR%\integrations\steam\redist\linux64\steam_bridge_native.so
echo Build this file first on Linux or Steam Deck Desktop Mode.
exit /b 1

:missing_steamapi
echo [ERROR] Missing Linux Steam runtime:
echo   %SCRIPT_DIR%\integrations\steam\redist\linux64\libsteam_api.so
exit /b 1

:build_failed
echo [ERROR] Linux package build failed.
exit /b 1
