-- Workaround for NVIDIA mouse-motion stalls with upscaling (Gamescope #1626).
-- Loaded only by dlssnr-upscale, before its Xwayland clients connect.
gamescope.convars.drm_debug_disable_explicit_sync.value = true
gamescope.log(gamescope.log_priority.info,
    "dlssnr-upscale: explicit sync disabled for mouse-stutter workaround")
