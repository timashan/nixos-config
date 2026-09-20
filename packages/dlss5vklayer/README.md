# DLSS5VKLayer on this laptop

The pinned public release includes the GUI, Wine helper, and 32/64-bit Vulkan
layers. It does not include NVIDIA's `nvngx_dlssnr.dll` model. Loading the layer
does not establish model compatibility or performance on the RTX 4050.

Build with `nix build .#dlss5vklayer`. The gaming module installs the package and
registers its manifests with both graphics environments. The layer stays disabled
until a game is launched with `dlssnr-run`.

For a user-only install without activating the system configuration:

```sh
nix profile add .#dlss5vklayer
dlssnr-helper setup
```

The helper uses a managed Wine prefix and downloads hash-verified DXVK/NVAPI
runtime components when needed. Its wrapper selects the NVIDIA GPU on this hybrid
laptop. The existing NVIDIA 580 driver pin remains unchanged.

Supply a compatible model DLL, then start the helper:

```sh
dlssnr-helper import-binaries /path/to/model-folder
dlssnr-helper doctor
dlssnr-gui
```

In the GUI, start the helper. For a Steam game, use these launch options:

```text
dlssnr-run nvidia-offload %command%
```

For 720p rendering with Gamescope FSR 1 upscaling to 1080p, use instead:

```text
nvidia-offload dlssnr-upscale %command%
```

Start the helper and enable neural processing in the GUI as above. Set the game's
resolution to 1280x720. The wrapper gives the game a 720p virtual display, enables
DLSS5VKLayer only for the game, then uses Gamescope to upscale the resulting frame
to a fullscreen 1080p output. NVIDIA offload goes outside the wrapper so it applies
to both the game and Gamescope. This is spatial FSR 1, not DLSS Super Resolution;
neural processing still costs GPU time, so measure performance in the game.

The wrapper loads a private Gamescope Lua script that disables explicit
synchronization before game clients connect. This resolved mouse-motion stutter
in Control on this NVIDIA setup, using the workaround reported in
[Gamescope issue #1626](https://github.com/ValveSoftware/gamescope/issues/1626#issuecomment-2636817984).
It applies only to `dlssnr-upscale` launches and keeps FSR and VKLayer enabled.
Restart the game after installing the change.

Optional dimensions can be supplied before the command, for example:

```text
DLSSNR_GAME_WIDTH=1600 DLSSNR_GAME_HEIGHT=900 nvidia-offload dlssnr-upscale %command%
```

Output dimensions use `DLSSNR_OUTPUT_WIDTH` and `DLSSNR_OUTPUT_HEIGHT` (defaults
1920 and 1080). This wrapper is for launching a game from the normal desktop;
avoid nesting it inside an existing Gamescope Steam session. Remove Swapper's
per-game injection with its Restore originals action before testing this path.
Changing Steam launch options alone does not remove those installed DLLs.

The wrapper selects Gamescope's SDL backend because its direct Wayland backend
failed the graphics smoke test on this NVIDIA/Hyprland setup. A Vulkan cube test
rendered with the layer loaded, but neural processing was disabled during that
test. Gamescope 3.16.23 also aborts during shutdown after the test app exits,
including without DLSS5VKLayer; this wrapper does not fix that upstream/runtime
issue. In-game neural output and performance still require verification.

The launcher enables the layer and sets `DLSSNR_SHM` to
`~/.local/share/dlssnr/runtime/shm.bin` (respecting `XDG_DATA_HOME`). The helper and
GUI use the same location. This is essential on NixOS: Steam's outer FHS container
has its own `/tmp`, so upstream's default gives the game and helper different files
even though their paths are identical. The launcher also exposes the shared
directory to pressure-vessel.

When migrating an existing upstream installation, close the old GUI and stop the
old helper first. Change `shm=` in `~/.config/dlssnr/config.ini` to the absolute
home-directory path above, then open the new GUI, start the helper, and restart
the game with the new launch options.

Check `~/.local/state/dlssnr/helper.log` to confirm neural initialization succeeds.
If initialization fails, the layer can pass through the original frames, so a
game launching successfully is not proof of active neural rendering. Close the
GUI or use `dlssnr-helper stop` to stop the helper; remove the launch option to
disable the layer for that game.

The package does not force global layer ordering or change `ptrace_scope`.
Upstream's zero-copy transport may fall back to copies under the system's current
ptrace policy. If using Smooth Motion too, consult upstream's layer-order guidance.
