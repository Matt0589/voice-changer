# VirtualAudioCableBridge (Windows)

This project provides a **user-mode bridge** that routes Windows playback audio into an already-installed virtual cable endpoint so Zoom/Skype/Discord can receive it as a microphone.

> Important: this is **not** a kernel virtual audio driver implementation. Building a full virtual audio cable driver requires a separate KMDF/AVStream driver project, code signing, and Windows driver packaging.

## What this app does

- Captures audio from a render device (`Speakers`, app output, etc.)
- Plays that stream to another render device (typically `CABLE Input` from VB-CABLE)
- Lets conferencing apps read from the paired capture endpoint (typically `CABLE Output`) as microphone input

## Requirements

1. Windows 10/11
2. .NET 8 SDK
3. A virtual cable driver already installed (e.g. VB-CABLE)


## Dotnet SDK installation helper (Linux CI/container)

If `dotnet` is missing, run:

```bash
bash ./install-dotnet.sh
```

The script tries multiple strategies in order:
1. Optional internal mirror overrides (`DOTNET_APT_MIRROR`, `DOTNET_INSTALL_SCRIPT_URL`, `DOTNET_SDK_TARBALL_URL`)
2. apt package install (`dotnet-sdk-8.0` by default)
3. Official `dotnet-install.sh` from `dot.net`
4. Official installer retry with proxy variables disabled
5. Local offline SDK tarballs in common paths
6. `mise install dotnet@<channel>` fallback

You can customize behavior with environment variables:

```bash
# Use internal apt mirror + internal hosted installer/tarball
DOTNET_APT_MIRROR="http://your-mirror.example.com/ubuntu" \
DOTNET_INSTALL_SCRIPT_URL="https://artifacts.example.com/dotnet/dotnet-install.sh" \
DOTNET_SDK_TARBALL_URL="https://artifacts.example.com/dotnet/dotnet-sdk-8.0-linux-x64.tar.gz" \
DOTNET_SDK_SHA512="<expected sha512>" \
DOTNET_SDK_PACKAGE="dotnet-sdk-8.0" \
bash ./install-dotnet.sh 8.0
```


## Windows install/start flow

To enforce a proper setup order on user PCs:

1. Run `install.bat` first (it opens a dedicated installer Command Prompt window).
2. After install succeeds, run `start.bat`.

`start.bat` will refuse to launch unless installation marker files exist.

### install.bat behavior

- Opens a new Command Prompt installer window.
- Verifies `dotnet` is available.
- Publishes the app if `publish/` output is missing.
- Copies build output into `%LOCALAPPDATA%\VirtualAudioCableBridge`.
- Writes `%LOCALAPPDATA%\VirtualAudioCableBridge\installed.flag` and `%LOCALAPPDATA%\VirtualAudioCableBridge\bridge.args.txt` (editable launch args template).

### start.bat behavior

- Checks for `%LOCALAPPDATA%\VirtualAudioCableBridge\installed.flag`.
- Reads the first non-comment line from `%LOCALAPPDATA%\VirtualAudioCableBridge\bridge.args.txt`.
- Refuses to launch if args are missing or still placeholders.
- Launches `%LOCALAPPDATA%\VirtualAudioCableBridge\VirtualAudioCableBridge.exe` if present.
- Falls back to `dotnet VirtualAudioCableBridge.dll` if only DLL exists.

## Build

```powershell
cd tools/windows/VirtualAudioCableBridge
dotnet restore
dotnet build -c Release
```

## Usage

List active render devices first:

```powershell
dotnet run -- --list
```

Run bridge (named args):

```powershell
dotnet run -- --source SOURCE_DEVICE --target TARGET_DEVICE --latency-ms 20 --buffer-ms 500
```

Run bridge (positional args):

```powershell
dotnet run -- "Speakers" "CABLE Input"
```

Then set your meeting app microphone to the matching cable capture endpoint (usually `CABLE Output`).

## Known limitations

- Not a replacement for a true virtual audio cable driver.
- Latency and stability depend on shared-mode WASAPI buffering and your installed cable driver.
- Protected audio paths and some DRM scenarios cannot be captured by loopback.
