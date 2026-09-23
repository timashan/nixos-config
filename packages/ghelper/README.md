# G-Helper NixOS compatibility fixes

The upstream v1.0.93 module supplies the application and system integration.
`overlay.nix` fixes its build against this repository's pinned nixpkgs:

- Use regenerated NuGet dependencies, excluding SDK-provided compiler packages.
- Supply libstdc++ when patching SkiaSharp's native Linux library.
- Install the native SkiaSharp and HarfBuzz libraries matching the resolved
  managed assemblies, rather than an older transitive dependency.
- Handle `TaskCanceledException` on the UI dispatcher only during shutdown.
  Avalonia 12.1.2's `DBusTrayIconImpl.WatchAsync` otherwise lets tray-disposal
  cancellation escape its `async void` method and abort the process on Quit.
  Exceptions outside shutdown and other exception types remain unhandled.

To regenerate `deps.json` after updating the G-Helper input:

```sh
nix build --impure --expr '(builtins.getFlake "git+file:///etc/nixos").inputs.ghelper.packages.x86_64-linux.default.fetch-deps' --out-link /tmp/ghelper-fetch-deps
/tmp/ghelper-fetch-deps /etc/nixos/packages/ghelper/deps.json
```

Check the native library versions in `overlay.nix` after regenerating. Remove
the overlay when upstream's package builds and installs the correct libraries
without these fixes.

To check the shutdown workaround, close G-Helper and run this from a desktop
session with a system tray (requires Python 3, busctl, and pgrep):

```sh
python3 packages/ghelper/check-quit.py /path/to/patched/bin/ghelper
```

The check launches the app and invokes its actual tray Quit action ten times.
It fails on abnormal exit or a fatal exception. The cancellation race is
intermittent; `cancellation handled=True` confirms the workaround was exercised.
