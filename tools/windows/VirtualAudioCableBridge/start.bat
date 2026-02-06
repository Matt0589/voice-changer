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
