@echo off
setlocal

set "PROJECT_ROOT=%~dp0"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

set "LOVE_RUNTIME_DIR=%PROJECT_ROOT%\LOVE_11_5_WIN64_RUNTIME_DROP"
set "OUTPUT_PARENT=%PROJECT_ROOT%\.."
set "OPENAL_OVERRIDE_DIR=%PROJECT_ROOT%\OPENAL_OVERRIDE_WIN64"
set "PACKAGE_DIR="
set "ZIP_PATH="

if exist "%SystemRoot%\py.exe" (
    set "PYTHON_CMD=py -3"
) else (
    set "PYTHON_CMD=python"
)

echo.
echo [1/2] Checking LOVE runtime folder...
if not exist "%LOVE_RUNTIME_DIR%\love.exe" goto :missing_runtime
if not exist "%LOVE_RUNTIME_DIR%\love.dll" goto :missing_runtime
if not exist "%LOVE_RUNTIME_DIR%\lua51.dll" goto :missing_runtime
if not exist "%LOVE_RUNTIME_DIR%\SDL2.dll" goto :missing_runtime
if not exist "%LOVE_RUNTIME_DIR%\OpenAL32.dll" goto :missing_runtime
if not exist "%LOVE_RUNTIME_DIR%\mpg123.dll" goto :missing_runtime
if not exist "%LOVE_RUNTIME_DIR%\msvcp120.dll" goto :missing_runtime
if not exist "%LOVE_RUNTIME_DIR%\msvcr120.dll" goto :missing_runtime

echo [2/2] Building final Windows package...
for /f "delims=" %%I in ('cmd /c %PYTHON_CMD% "%PROJECT_ROOT%\scripts\build_fused_windows_package.py" --source-project "%PROJECT_ROOT%" --love-runtime-dir "%LOVE_RUNTIME_DIR%" --output-parent "%OUTPUT_PARENT%" --openal-override-dir "%OPENAL_OVERRIDE_DIR%"') do (
    if not defined PACKAGE_DIR (
        set "PACKAGE_DIR=%%I"
    )
)

if not defined PACKAGE_DIR (
    echo Failed to build the final Windows package.
    exit /b 1
)

echo.
echo Final package folder:
echo %PACKAGE_DIR%
if exist "%PACKAGE_DIR%\VALIDATION_REPORT.txt" (
    echo Validation report:
    echo %PACKAGE_DIR%\VALIDATION_REPORT.txt
)
echo.
echo Done.
exit /b 0

:missing_runtime
echo Missing one or more required LOVE 11.5 runtime files in:
echo %LOVE_RUNTIME_DIR%
echo.
echo Required files:
echo - love.exe
echo - love.dll
echo - lua51.dll
echo - SDL2.dll
echo - OpenAL32.dll
echo - mpg123.dll
echo - msvcp120.dll
echo - msvcr120.dll
exit /b 1
