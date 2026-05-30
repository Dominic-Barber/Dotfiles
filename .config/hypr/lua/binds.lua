local mainMod = "SUPER"
local terminal = "ghostty"
local fileManager = "dolphin"

-- Standard App Binds
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("~/.config/hypr/autoclick.sh"))
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.float())
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("dolphin"))
-- Noctalia IPC Binds
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call launcher toggle"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call panel-toggle notifications"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("qs -c noctalia-shell ipc call lockScreen lock"))

-- Clipboard
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))

-- Window Management (Mouse & Keys behaving like Mouse)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + ALT + left", hl.dsp.window.resize(), { mouse = true })

-- Use a loop to automatically bind SUPER + 1 through 9 (and 0 for workspace 10)
for i = 1, 10 do
    local key = i == 10 and "0" or tostring(i)
    
    -- Switch focus to workspace i using SUPER + number
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
    
    -- Move focused window to workspace i using SUPER + SHIFT + number
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Switch to the next workspace on the current monitor
hl.bind("SUPER + right", hl.dsp.focus({ workspace = "m+1" }))

-- Switch to the previous workspace on the current monitor
hl.bind("SUPER + left", hl.dsp.focus({ workspace = "m-1" }))

-- Optional: Move the focused window to the next/prev workspace on the current monitor
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ workspace = "m+1" }))
hl.bind("SUPER + SHIFT + left", hl.dsp.window.move({ workspace = "m-1" }))

-- Resize Active
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -10, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -10, relative = true }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 10, relative = true }))

-- Volume Control
-- Raise Volume (repeating = true allows it to trigger continuously when held down)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 1%+"), { repeating = false })

-- Lower Volume
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 1%-"), { repeating = false })

-- Toggle Mute (no repeating flag needed)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))


-- Screenshoting
-- Screenshot a region
hl.bind(mainMod .. " + SHIFT + s", hl.dsp.exec_cmd("hyprshot -m region"))

-- Screenshot the active window
hl.bind(mainMod .. " + s", hl.dsp.exec_cmd("hyprshot -m window"))

