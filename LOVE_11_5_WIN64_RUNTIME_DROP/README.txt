Put the Windows LOVE 11.5 runtime files in this folder.

Required files:
- love.exe
- love.dll
- lua51.dll
- SDL2.dll
- OpenAL32.dll
- mpg123.dll
- msvcp120.dll
- msvcr120.dll

Workflow:
1. Drop the files above into this folder.
2. Run `MAKE_WINDOWS_PACKAGE.bat` from the main project root for a test build folder.
3. Run `MAKE_WINDOWS_PACKAGE_TEST_ZIP.bat` for a test build folder plus zip.
4. Run `MAKE_WINDOWS_PACKAGE_RELEASE.bat` for a release build that removes `steam_appid.txt` and also creates a zip.

Notes:
- This folder is only for the Windows LOVE runtime input.
- Steam files are taken from the main project itself and copied automatically.
- No separate fused prep folder is required for the normal packaging workflow.
- Each generated package folder includes `VALIDATION_REPORT.txt`.
- If required packaged files are missing, the build exits with an error and lists them.

Optional Remote Play audio test override:
- If you want to test a newer OpenAL runtime, put an alternate `OpenAL32.dll` in `OPENAL_OVERRIDE_WIN64/`.
- The Windows build scripts will automatically use that file instead of the LOVE runtime `OpenAL32.dll`.
- If the folder is empty, the default LOVE runtime `OpenAL32.dll` is used.
