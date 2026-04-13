Optional OpenAL override folder for Remote Play audio testing.

Usage:
1. Put a replacement OpenAL32.dll in this folder.
2. Run MAKE_WINDOWS_PACKAGE_TEST_ZIP.bat (or the other packaging batch).
3. The build script will automatically use this OpenAL32.dll instead of the one from LOVE_11_5_WIN64_RUNTIME_DROP.

If this folder does not contain OpenAL32.dll, the normal LOVE runtime OpenAL32.dll is used.
