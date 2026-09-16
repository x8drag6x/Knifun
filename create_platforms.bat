@echo off
setlocal
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter SDK was not found in PATH.
  echo Install Flutter, then open CMD in this folder and run this file again.
  exit /b 1
)
flutter create . --platforms=android,windows
if errorlevel 1 exit /b 1
flutter pub get
if errorlevel 1 exit /b 1
flutter run
