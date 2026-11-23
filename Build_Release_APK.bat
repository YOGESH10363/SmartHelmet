@echo off
title Smart Helmet 2.0 - APK Builder
echo ============================================================
echo   Smart Helmet 2.0 - Automated Release APK Builder
echo ============================================================
echo.

:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges to apply Windows Security exclusions...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

echo [1/3] Adding Windows Security exclusion for Flutter and Project...
powershell -Command "Add-MpPreference -ExclusionPath 'D:\flutter', '%~dp0' -ErrorAction SilentlyContinue"

echo [2/3] Configuring Java 27 and Flutter environment...
set "PATH=D:\flutter\bin;%PATH%"
set "JAVA_HOME=C:\Program Files\Java\jdk-27.0.1.0.3"

echo [3/3] Compiling Release APK (flutter build apk --release)...
cd /d "%~dp0"
call flutter build apk --release

echo.
if exist "%~dp0build\app\outputs\flutter-apk\app-release.apk" (
    echo ============================================================
    echo   BUILD SUCCESSFUL!
    echo   APK File: %~dp0build\app\outputs\flutter-apk\app-release.apk
    echo ============================================================
    explorer "%~dp0build\app\outputs\flutter-apk"
) else (
    echo ============================================================
    echo   Windows Smart App Control is strictly blocking local binaries.
    echo   Push this repository to GitHub to build the APK in 2 minutes
    echo   using the included .github/workflows/build_apk.yml workflow!
    echo ============================================================
)

pause
