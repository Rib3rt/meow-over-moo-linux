@echo off
setlocal EnableExtensions

call "%~dp0BUILD_LINUX_STEAM_BRIDGE_WSL.bat"
if errorlevel 1 exit /b 1
call "%~dp0MAKE_LINUX_PACKAGE.bat"
exit /b %errorlevel%
