@echo off
setlocal EnableExtensions

title dotnet installer: MUST BE INSTALLED TO INSTALL THE VAC!

echo.
echo ===============================================================
echo   dotnet installer: MUST BE INSTALLED TO INSTALL THE VAC!
echo ===============================================================
echo This script installs the .NET 8 SDK required by VirtualAudioCableBridge.
echo.

where dotnet >nul 2>nul
if not errorlevel 1 (
  echo .NET is already installed and available in PATH.
  dotnet --version
  echo.
  echo No further action is required.
  pause
  exit /b 0
)

where winget >nul 2>nul
if errorlevel 1 (
  echo ERROR: winget is not available on this system.
  echo Please install .NET 8 SDK manually from:
  echo https://dotnet.microsoft.com/en-us/download/dotnet/8.0
  echo.
  pause
  exit /b 1
)

echo Installing .NET 8 SDK with winget...
winget install --id Microsoft.DotNet.SDK.8 --exact --accept-package-agreements --accept-source-agreements
if errorlevel 1 (
  echo ERROR: winget installation failed.
  echo Try running this script as Administrator and ensure internet access.
  pause
  exit /b 1
)

echo.
echo Verifying dotnet installation...
where dotnet >nul 2>nul
if errorlevel 1 (
  echo ERROR: .NET install command completed, but dotnet is still not found in PATH.
  echo You may need to reopen Command Prompt or restart Windows.
  pause
  exit /b 1
)

dotnet --version
echo.
echo SUCCESS: .NET 8 SDK is installed. You can now run install.bat for VAC.
pause
exit /b 0
