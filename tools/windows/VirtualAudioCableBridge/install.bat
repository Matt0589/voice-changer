@echo off
setlocal EnableExtensions

REM Relaunch to auto-run inside a visible, persistent Command Prompt window.
if /I "%~1" NEQ "__run" (
  start "VAC Installer" cmd /k ""%~f0" __run"
  exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "INSTALL_DIR=%LOCALAPPDATA%\VirtualAudioCableBridge"
set "PUBLISH_DIR=%SCRIPT_DIR%publish"
set "EXE_NAME=VirtualAudioCableBridge.exe"
set "DLL_NAME=VirtualAudioCableBridge.dll"
set "MARKER_FILE=%INSTALL_DIR%\installed.flag"
set "ARGS_FILE=%INSTALL_DIR%\bridge.args.txt"

echo.
echo ==============================================
echo   VirtualAudioCableBridge - Installer
echo ==============================================
echo This installer will automatically install the required files; no input is needed.
echo.

echo [1/6] Checking prerequisites...
where dotnet >nul 2>nul
if errorlevel 1 (
  echo ERROR: dotnet was not found in PATH.
  echo Please install .NET 8 SDK first (or use install-dotnet.sh in CI/container).
  pause
  exit /b 1
)

echo [2/6] Preparing build output...
if not exist "%PUBLISH_DIR%\%EXE_NAME%" (
  echo No prebuilt executable found in "%PUBLISH_DIR%".
  echo Running dotnet publish now...
  pushd "%SCRIPT_DIR%"
  dotnet publish -c Release -r win-x64 --self-contained false -o "%PUBLISH_DIR%"
  if errorlevel 1 (
    popd
    echo ERROR: dotnet publish failed.
    pause
    exit /b 1
  )
  popd
)

if not exist "%PUBLISH_DIR%\%EXE_NAME%" if not exist "%PUBLISH_DIR%\%DLL_NAME%" (
  echo ERROR: publish output is missing both EXE and DLL.
  pause
  exit /b 1
)

echo [3/6] Creating install directory...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if errorlevel 1 (
  echo ERROR: failed to create install directory "%INSTALL_DIR%".
  pause
  exit /b 1
)

echo [4/6] Copying files...
xcopy "%PUBLISH_DIR%\*" "%INSTALL_DIR%\" /E /I /Y >nul
if errorlevel 1 (
  echo ERROR: failed while copying files.
  pause
  exit /b 1
)

copy /Y "%SCRIPT_DIR%start.bat" "%INSTALL_DIR%\start.bat" >nul 2>nul

echo [5/6] Writing launch configuration template...
if not exist "%ARGS_FILE%" (
  (
    echo # One line of CLI args for VirtualAudioCableBridge.
    echo # Edit source/target before first launch.
    echo --source SOURCE_DEVICE --target TARGET_DEVICE --latency-ms 20 --buffer-ms 500
  ) > "%ARGS_FILE%"
)

(
  echo installed_at=%DATE% %TIME%
  echo source_dir=%SCRIPT_DIR%
  echo install_dir=%INSTALL_DIR%
) > "%MARKER_FILE%"

echo [6/6] Installation complete.
echo Installed to: "%INSTALL_DIR%"
echo.
echo IMPORTANT: Edit "%ARGS_FILE%" with your real device names before running start.bat.
echo Tip: run "%INSTALL_DIR%\VirtualAudioCableBridge.exe" --list to discover exact names.
echo.
exit /b 0
tools/windows/VirtualAudioCableBridge/start.bat
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
