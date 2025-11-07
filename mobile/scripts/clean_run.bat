@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Navigate to project root of mobile (this script is placed in mobile\scripts)
cd /d "%~dp0.."

call "%~dp0kill_locks.bat"

REM Best-effort remove build artifacts that usually get locked on Windows + OneDrive
for %%D in (build .dart_tool .packages .gradle) do (
  if exist "%%D" (
    echo Deleting %%D ...
    rmdir /S /Q "%%D" >NUL 2>&1
  )
)
if exist "android\\app\\build" rmdir /S /Q "android\\app\\build" >NUL 2>&1
if exist "build" rmdir /S /Q "build" >NUL 2>&1

REM Flutter clean can still help
flutter clean

REM Restore deps
flutter pub get

REM Optional: regenerate icons if config present
if exist "pubspec.yaml" (
  findstr /C:"flutter_launcher_icons:" pubspec.yaml >NUL
  if "%ERRORLEVEL%"=="0" (
    echo Running flutter_launcher_icons...
    flutter pub run flutter_launcher_icons >NUL 2>&1
  )
)

REM Run on last used device (or specify -d as first arg)
set DEVICE=%1
if not "%DEVICE%"=="" (
  flutter run -d %DEVICE%
) else (
  flutter run
)
