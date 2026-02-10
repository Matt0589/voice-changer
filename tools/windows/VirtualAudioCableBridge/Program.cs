using NAudio.CoreAudioApi;
using NAudio.Wave;

namespace VirtualAudioCableBridge;

internal static class Program
{
    private sealed record Options(bool ListOnly, string? SourceMatch, string? TargetMatch, int LatencyMs, int BufferMs);

    private static int Main(string[] args)
    {
        var options = ParseArgs(args);
        using var enumerator = new MMDeviceEnumerator();

        if (options.ListOnly)
        {
            PrintDevices(enumerator, DataFlow.Render);
            return 0;
        }

        if (string.IsNullOrWhiteSpace(options.SourceMatch) || string.IsNullOrWhiteSpace(options.TargetMatch))
        {
            PrintUsage();
            return 1;
        }

        var sourceDevice = FindRenderDevice(enumerator, options.SourceMatch);
        var targetDevice = FindRenderDevice(enumerator, options.TargetMatch);

        if (sourceDevice is null)
        {
            Console.Error.WriteLine($"[error] Source render device not found: {options.SourceMatch}");
            PrintDevices(enumerator, DataFlow.Render);
            return 2;
        }

        if (targetDevice is null)
        {
            Console.Error.WriteLine($"[error] Target virtual cable input not found: {options.TargetMatch}");
            PrintDevices(enumerator, DataFlow.Render);
            return 3;
        }

        return RunBridge(sourceDevice, targetDevice, options);
    }

    private static int RunBridge(MMDevice sourceDevice, MMDevice targetDevice, Options options)
    {
        using var capture = new WasapiLoopbackCapture(sourceDevice);
        using var playback = new WasapiOut(targetDevice, AudioClientShareMode.Shared, false, options.LatencyMs);

        var buffer = new BufferedWaveProvider(capture.WaveFormat)
        {
            BufferDuration = TimeSpan.FromMilliseconds(options.BufferMs),
            DiscardOnBufferOverflow = true,
            ReadFully = true
        };

        long droppedBytes = 0;
        capture.DataAvailable += (_, eventArgs) =>
        {
            int freeBytes = buffer.BufferLength - buffer.BufferedBytes;
            if (eventArgs.BytesRecorded > freeBytes)
            {
                droppedBytes += eventArgs.BytesRecorded - freeBytes;
            }

            buffer.AddSamples(eventArgs.Buffer, 0, eventArgs.BytesRecorded);
        };

        capture.RecordingStopped += (_, eventArgs) =>
        {
            if (eventArgs.Exception is not null)
            {
                Console.Error.WriteLine($"[error] Capture stopped: {eventArgs.Exception.Message}");
            }
        };

        playback.Init(buffer);

        Console.WriteLine("[info] VirtualAudioCableBridge started.");
        Console.WriteLine($"[info] Source : {sourceDevice.FriendlyName}");
        Console.WriteLine($"[info] Target : {targetDevice.FriendlyName}");
        Console.WriteLine($"[info] Format : {capture.WaveFormat}");
        Console.WriteLine($"[info] Latency: {options.LatencyMs} ms, Buffer: {options.BufferMs} ms");
        Console.WriteLine("[info] In conferencing apps, select your cable capture endpoint (usually 'CABLE Output') as microphone.");
        Console.WriteLine("[info] Press Ctrl+C to stop.");

        using var stopEvent = new ManualResetEventSlim(false);
        ConsoleCancelEventHandler cancelHandler = (_, eventArgs) =>
        {
            eventArgs.Cancel = true;
            stopEvent.Set();
        };

        Console.CancelKeyPress += cancelHandler;

        try
        {
            capture.StartRecording();
            playback.Play();

            while (!stopEvent.IsSet)
            {
                Thread.Sleep(1000);
                Console.WriteLine($"[stats] buffered={buffer.BufferedDuration.TotalMilliseconds:F0} ms droppedBytes={droppedBytes}");
            }

            capture.StopRecording();
            playback.Stop();
            Console.WriteLine("[info] Bridge stopped.");
            return 0;
        }
        finally
        {
            Console.CancelKeyPress -= cancelHandler;
        }
    }

    private static MMDevice? FindRenderDevice(MMDeviceEnumerator enumerator, string match)
    {
        foreach (var device in enumerator.EnumerateAudioEndPoints(DataFlow.Render, DeviceState.Active))
        {
            if (device.FriendlyName.Contains(match, StringComparison.OrdinalIgnoreCase) ||
                device.ID.Contains(match, StringComparison.OrdinalIgnoreCase))
            {
                return device;
            }
        }

        return null;
    }

    private static void PrintDevices(MMDeviceEnumerator enumerator, DataFlow flow)
    {
        Console.WriteLine("[info] Active render devices:");
        foreach (var device in enumerator.EnumerateAudioEndPoints(flow, DeviceState.Active))
        {
            Console.WriteLine($"  - Name: {device.FriendlyName}");
            Console.WriteLine($"    Id  : {device.ID}");
        }
    }

    private static Options ParseArgs(string[] args)
    {
        bool listOnly = args.Any(arg => arg is "--list" or "-l");
        string? source = null;
        string? target = null;
        int latencyMs = 20;
        int bufferMs = 500;

        for (int i = 0; i < args.Length; i++)
        {
            switch (args[i])
            {
                case "--source" when i + 1 < args.Length:
                    source = args[++i];
                    break;
                case "--target" when i + 1 < args.Length:
                    target = args[++i];
                    break;
                case "--latency-ms" when i + 1 < args.Length && int.TryParse(args[++i], out var parsedLatency):
                    latencyMs = Math.Clamp(parsedLatency, 5, 500);
                    break;
                case "--buffer-ms" when i + 1 < args.Length && int.TryParse(args[++i], out var parsedBuffer):
                    bufferMs = Math.Clamp(parsedBuffer, 50, 5000);
                    break;
            }
        }

        // Backward-compatible positional arguments: <sourceMatch> <targetMatch>
        if (source is null && args.Length >= 1 && !args[0].StartsWith('-')) source = args[0];
        if (target is null && args.Length >= 2 && !args[1].StartsWith('-')) target = args[1];

        return new Options(listOnly, source, target, latencyMs, bufferMs);
    }

    private static void PrintUsage()
    {
        Console.WriteLine("VirtualAudioCableBridge - route Windows playback audio into a virtual cable input.");
        Console.WriteLine();
        Console.WriteLine("Usage:");
        Console.WriteLine("  VirtualAudioCableBridge.exe --list");
        Console.WriteLine("  VirtualAudioCableBridge.exe --source \"Speakers\" --target \"CABLE Input\" [--latency-ms 20] [--buffer-ms 500]");
        Console.WriteLine("  VirtualAudioCableBridge.exe \"Speakers\" \"CABLE Input\"");
        Console.WriteLine();
        Console.WriteLine("Typical conferencing setup:");
        Console.WriteLine("  1) Route audio to virtual cable input with this app.");
        Console.WriteLine("  2) In Zoom/Discord/Skype select the matching cable capture endpoint (usually 'CABLE Output') as microphone.");
    }
}
