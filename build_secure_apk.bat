@echo off
echo ===============================================================
echo       VetPulse Production Build Script (Hardened & Obfuscated)
echo ===============================================================
echo.
echo [1/3] Running tests and verification...
call flutter test test/licensing_test.dart
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Unit tests failed. Build aborted.
    exit /b %ERRORLEVEL%
)

echo.
echo [2/3] Cleaning previous build artifacts...
call flutter clean
call flutter pub get

echo.
echo [3/3] Compiling Secure Release APK with R8 and Symbol Obfuscation...
call flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ===============================================================
    echo [SUCCESS] Secure APK created successfully!
    echo Output: build\app\outputs\flutter-apk\app-release.apk
    echo Debug symbols saved in: build\app\outputs\symbols
    echo ===============================================================
) else (
    echo.
    echo [ERROR] Build failed with exit code %ERRORLEVEL%.
)
