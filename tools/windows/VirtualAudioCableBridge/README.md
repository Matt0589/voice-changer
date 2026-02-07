diff --git a/tools/windows/VirtualAudioCableBridge/README.md b/tools/windows/VirtualAudioCableBridge/README.md
index cb82fa1e3f265bcba818fecfd3e12d45a8a3859d..53538362b04086bbfe0b36c38cdfbb899869777c 100644
--- a/tools/windows/VirtualAudioCableBridge/README.md
+++ b/tools/windows/VirtualAudioCableBridge/README.md
@@ -1,108 +1,86 @@
 # VirtualAudioCableBridge (Windows)
 
 This project provides a **user-mode bridge** that routes Windows playback audio into an already-installed virtual cable endpoint so Zoom/Skype/Discord can receive it as a microphone.
 
 > Important: this is **not** a kernel virtual audio driver implementation. Building a full virtual audio cable driver requires a separate KMDF/AVStream driver project, code signing, and Windows driver packaging.
 
 ## What this app does
 
 - Captures audio from a render device (`Speakers`, app output, etc.)
 - Plays that stream to another render device (typically `CABLE Input` from VB-CABLE)
 - Lets conferencing apps read from the paired capture endpoint (typically `CABLE Output`) as microphone input
 
 ## Requirements
 
 1. Windows 10/11
2. A virtual cable driver already installed (e.g. VB-CABLE)
3. A prebuilt `VirtualAudioCableBridge.exe` (downloaded from Releases)
 
## Getting the EXE
 
+Download `VirtualAudioCableBridge.exe` from the project Releases page and place it in
`tools/windows/VirtualAudioCableBridge/publish/`, or provide the file path/URL when
`install.bat` prompts you:
 
 https://github.com/w-okada/voice-changer/releases
 
 ## Windows install/start flow
 
 To enforce a proper setup order on user PCs:
 
 1. Run `install.bat` first (it opens a dedicated installer Command Prompt window).
 2. After install succeeds, run `start.bat`.
 
 `start.bat` will refuse to launch unless installation marker files exist.
 
 ### install.bat behavior
 
 - Opens a new Command Prompt installer window.
- Requires a prebuilt `publish/VirtualAudioCableBridge.exe` (or prompts for a local path/URL).
 - Copies build output into `%LOCALAPPDATA%\VirtualAudioCableBridge`.
 - Writes `%LOCALAPPDATA%\VirtualAudioCableBridge\installed.flag` and `%LOCALAPPDATA%\VirtualAudioCableBridge\bridge.args.txt` (editable launch args template).
 
 ### start.bat behavior
 
 - Checks for `%LOCALAPPDATA%\VirtualAudioCableBridge\installed.flag`.
 - Reads the first non-comment line from `%LOCALAPPDATA%\VirtualAudioCableBridge\bridge.args.txt`.
 - Refuses to launch if args are missing or still placeholders.
 - Launches `%LOCALAPPDATA%\VirtualAudioCableBridge\VirtualAudioCableBridge.exe` if present.
 
 ## Build
 
+If you prefer to build the EXE yourself, you will need the .NET SDK:
+
 ```powershell
 cd tools/windows/VirtualAudioCableBridge
 dotnet restore
 dotnet build -c Release
 ```
 
 ## Usage
 
 List active render devices first:
 
 ```powershell
VirtualAudioCableBridge.exe --list
 ```
 
 Run bridge (named args):
 
 ```powershell
VirtualAudioCableBridge.exe --source SOURCE_DEVICE --target TARGET_DEVICE --latency-ms 20 --buffer-ms 500
 ```
 
 Run bridge (positional args):
 
 ```powershell
VirtualAudioCableBridge.exe -- "Speakers" "CABLE Input"
 ```
 
 Then set your meeting app microphone to the matching cable capture endpoint (usually `CABLE Output`).
 
 ## Known limitations
 
 - Not a replacement for a true virtual audio cable driver.
 - Latency and stability depend on shared-mode WASAPI buffering and your installed cable driver.
 - Protected audio paths and some DRM scenarios cannot be captured by loopback.
