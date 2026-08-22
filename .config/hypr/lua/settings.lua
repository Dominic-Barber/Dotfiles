hl.config({
    xwayland = {
        force_zero_scaling = true
    }
})

hl.monitor({
    output = "DP-2",
    mode = "3440x1440@240",
    position = "0x0",
    scale = 1,
    bitdepth = 10,
    cm = "srgb",
    supports_hdr = 1
})

hl.monitor({
    output = "DP-1",
    mode = "3840x2160@60",
    position = "3440x0",
    scale = 1.33,
    cm = "srgb",
    supports_hdr = 1
})


hl.dispatch(hl.dsp.exec_cmd("hyprctl keyword render:cm_fs_passthrough 1"))
