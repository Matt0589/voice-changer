@echo off
setlocal EnableExtensions

REM Relaunch to auto-run inside a visible, persistent Command Prompt window.
if /I "%~1" NEQ "__run" (
  start "VirtualAudioCableBridge Launcher" cmd /k ""%~f0" __run"
  exit /b 0
)

set "INSTALL_DIR=%LOCALAPPDATA%\VirtualAudioCableBridge"
set "MARKER_FILE=%INSTALL_DIR%\installed.flag"
set "ARGS_FILE=%INSTALL_DIR%\bridge.args.txt"
set "EXE_PATH=%INSTALL_DIR%\VirtualAudioCableBridge.exe"
set "DLL_PATH=%INSTALL_DIR%\VirtualAudioCableBridge.dll"

if not exist "%MARKER_FILE%" (
  echo ERROR: VirtualAudioCableBridge is not installed yet.
  echo Please run install.bat first.
  pause
  exit /b 1
)

if not exist "%ARGS_FILE%" (
  echo ERROR: launch args file missing: "%ARGS_FILE%"
  echo Re-run install.bat.
  pause
  exit /b 1
)

set "ARGS_LINE="
for /f "usebackq tokens=* delims=" %%L in (`powershell -NoProfile -Command "Get-Content -Path '%ARGS_FILE%' | Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') } | Select-Object -First 1"`) do set "ARGS_LINE=%%L"

if "%ARGS_LINE%"=="" (
  echo ERROR: no launch arguments found in "%ARGS_FILE%".
  echo Add a line like:
  echo --source "Speakers" --target "CABLE Input" --latency-ms 20 --buffer-ms 500
  pause
  exit /b 1
)

echo %ARGS_LINE% | findstr /I /C:"SOURCE_DEVICE" /C:"TARGET_DEVICE" >nul
if not errorlevel 1 (
  echo WARNING: args file still has default placeholder values.
  echo Edit "%ARGS_FILE%" with your actual source/target device names.
  echo To discover names, run: "%INSTALL_DIR%\VirtualAudioCableBridge.exe" --list
  pause
  exit /b 1
)

if exist "%EXE_PATH%" (
  echo Launching VirtualAudioCableBridge with args from bridge.args.txt...
  start "VirtualAudioCableBridge" "%EXE_PATH%" %ARGS_LINE%
  exit /b 0
)

if exist "%DLL_PATH%" (
  where dotnet >nul 2>nul
  if errorlevel 1 (
    echo ERROR: dotnet runtime was not found in PATH.
    echo Install .NET runtime/SDK and try again.
    pause
    exit /b 1
  )

  echo Launching VirtualAudioCableBridge via dotnet with args from bridge.args.txt...
  start "VirtualAudioCableBridge" dotnet "%DLL_PATH%" %ARGS_LINE%
  exit /b 0
)

echo ERROR: installed bridge binary not found in "%INSTALL_DIR%".
echo Re-run install.bat.
pause
exit /b 1
