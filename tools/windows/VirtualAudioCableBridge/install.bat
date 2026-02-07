 @echo off
 setlocal EnableExtensions
 
 REM Relaunch to auto-run inside a visible, persistent Command Prompt window.
 if /I "%~1" NEQ "__run" (
   start "VAC Installer" "%ComSpec%" /d /k call "%~f0" __run
   exit /b 0
 )
 
 set "SCRIPT_DIR=%~dp0"
 set "INSTALL_DIR=%LOCALAPPDATA%\VirtualAudioCableBridge"
 set "PUBLISH_DIR=%SCRIPT_DIR%publish"
 set "EXE_NAME=VirtualAudioCableBridge.exe"
 set "MARKER_FILE=%INSTALL_DIR%\installed.flag"
 set "ARGS_FILE=%INSTALL_DIR%\bridge.args.txt"
 
 echo.
 echo ==============================================
 echo   VirtualAudioCableBridge - Installer
 echo ==============================================
echo This installer installs a prebuilt executable only.
 echo.
 
 echo.
 echo Type "run installer" and press Enter to begin installation.
 set /p "USER_CONFIRM=> "
 if /I not "%USER_CONFIRM%"=="run installer" (
   echo Installation cancelled.
   echo You must type exactly: run installer
   pause
   exit /b 1
 )
 echo.
 
  echo WARNING: required prebuilt executable was not found:
  echo   "%PUBLISH_DIR%\%EXE_NAME%"
  echo.
  echo This installer no longer builds with dotnet.
  echo Download VirtualAudioCableBridge.exe from the GitHub Releases page:
  echo   https://github.com/w-okada/voice-changer/releases
  echo Then provide the local EXE path or a direct download URL below.
  echo Leave blank to cancel.
  echo.
  set "EXE_SOURCE="
  set /p "EXE_SOURCE=EXE path or URL> "
  if "%EXE_SOURCE%"=="" (
    echo Installation cancelled.
     pause
     exit /b 1
   )
 
  echo %EXE_SOURCE% | findstr /I /R "^https\\?://" >nul
  if not errorlevel 1 (
    echo Downloading "%EXE_NAME%"...
    if not exist "%PUBLISH_DIR%" mkdir "%PUBLISH_DIR%"
    powershell -NoProfile -Command "try { Invoke-WebRequest -Uri '%EXE_SOURCE%' -OutFile '%PUBLISH_DIR%\\%EXE_NAME%' -UseBasicParsing } catch { exit 1 }"
    if errorlevel 1 (
      echo ERROR: failed to download "%EXE_NAME%".
      pause
      exit /b 1
    )
  ) else (
    if not exist "%EXE_SOURCE%" (
      echo ERROR: file not found: "%EXE_SOURCE%"
      pause
      exit /b 1
    )
    if not exist "%PUBLISH_DIR%" mkdir "%PUBLISH_DIR%"
    copy /Y "%EXE_SOURCE%" "%PUBLISH_DIR%\\%EXE_NAME%" >nul
    if errorlevel 1 (
      echo ERROR: failed to copy "%EXE_SOURCE%" to "%PUBLISH_DIR%\\%EXE_NAME%".
      pause
      exit /b 1
    )
   )
 )
 
echo [2/5] Creating install directory...
 if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
 if errorlevel 1 (
   echo ERROR: failed to create install directory "%INSTALL_DIR%".
   pause
   exit /b 1
 )
 
echo [3/5] Copying files...
 xcopy "%PUBLISH_DIR%\*" "%INSTALL_DIR%\" /E /I /Y >nul
 if errorlevel 1 (
   echo ERROR: failed while copying files.
   pause
   exit /b 1
 )
 
 copy /Y "%SCRIPT_DIR%start.bat" "%INSTALL_DIR%\start.bat" >nul 2>nul
 
echo [4/5] Writing launch configuration template...
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
 
echo [5/5] Installation complete.
 echo Installed to: "%INSTALL_DIR%"
 echo.
 echo IMPORTANT: Edit "%ARGS_FILE%" with your real device names before running start.bat.
 echo Tip: run "%INSTALL_DIR%\VirtualAudioCableBridge.exe" --list to discover exact names.
 echo.
 exit /b 0
