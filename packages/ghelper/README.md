# G-Helper NixOS compatibility fixes

The upstream v1.0.93 module supplies the application and system integration.
`overlay.nix` fixes its build against this repository's pinned nixpkgs:

- Use regenerated NuGet dependencies, excluding SDK-provided compiler packages.
- Supply libstdc++ when patching SkiaSharp's native Linux library.
- Install the native SkiaSharp and HarfBuzz libraries matching the resolved
  managed assemblies, rather than an older transitive dependency.

To regenerate `deps.json` after updating the G-Helper input:

```sh
nix build --impure --expr '(builtins.getFlake "git+file:///etc/nixos").inputs.ghelper.packages.x86_64-linux.default.fetch-deps' --out-link /tmp/ghelper-fetch-deps
/tmp/ghelper-fetch-deps /etc/nixos/packages/ghelper/deps.json
```

Check the native library versions in `overlay.nix` after regenerating. Remove
the overlay when upstream's package builds and installs the correct libraries
without these fixes.
