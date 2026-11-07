# Power Modes Spec (ASUS ProArt PX13 HN7306WU)

Status: draft. Nothing here is implemented yet.

## Goal

Three power modes, shown in the Noctalia bar. The bar item shows the current mode, and clicking it lets the user pick another.

| Mode | Label | Intent |
|---|---|---|
| Eco | `eco` | Maximum battery. Quiet fans, dGPU disabled, low brightness. |
| Dynamic | `dyn` | Default. dGPU powered down until an app asks for it. |
| Performance | `pwr` | Maximum speed. dGPU awake, and primary for Hyprland if feasible. |

The panel is 60 Hz only, so refresh rate is not a mode variable.

## Hardware facts (verified on this machine)

- iGPU: AMD Radeon 890M at `0000:c5:00.0` (driver `amdgpu`). dGPU: RTX 4050 at `0000:c4:00.0` (BIOS `HN7306WU.318`), behind root port `00:03.1`.
- Backlight device: `amdgpu_bl1`. Control with `brightnessctl -d amdgpu_bl1`.
- Platform profile is exposed by `asusd` (`asusctl profile`) and `/sys/devices/platform/asus-nb-wmi/throttle_thermal_policy`.
- `asusctl armoury` exposes no `dgpu_disable` or `gpu_mux_mode` attribute on this model. The dGPU cannot be toggled through ASUS firmware from Linux. `supergfxctl` is therefore not usable.
- Removing the dGPU at runtime works via PCI remove, and bringing it back via PCI rescan. Both need root.
- Hyprland picks its GPUs from `AQ_DRM_DEVICES` (set in `~/.config/hypr/lua/env.lua`). This is read at compositor start, so changing it needs a restart of Hyprland.

## Per-mode settings

| Setting | eco | dyn | pwr |
|---|---|---|---|
| `asusctl profile` / platform profile | Quiet | Balanced | Performance |
| `power-profiles-daemon` | power-saver | balanced | performance |
| dGPU state | Removed from the PCI bus (nvidia modules unloaded first) | Present, runtime PM `auto` (suspends when idle) | Present, runtime PM `on` (always awake) |
| Hyprland primary GPU | AMD iGPU | AMD iGPU | NVIDIA dGPU first, AMD second (takes effect after Hyprland restart) |
| Brightness | cap at 30% (restore previous on leaving eco) | unchanged | unchanged |
| `nvidia-powerd` (Dynamic Boost) | stopped | running | running |
| Fan curve | quiet | default | default |
| Keyboard backlight | off | unchanged | unchanged |

## Mechanism

A single script, `~/.config/hypr/scripts/powermode`, is the source of truth.

- `powermode get` prints `eco`, `dyn` or `pwr`.
- `powermode set <eco|dyn|pwr>` applies the settings above.
- `powermode list` prints all modes (for the picker).
- The current mode is stored in `~/.local/state/powermode` so it survives reboots and can be read cheaply by the bar item.
- A systemd unit (`powermode-restore.service`) re-applies the saved mode at boot.

### Privileges

The dGPU removal, runtime PM `on`/`auto`, unloading modules and starting `nvidia-powerd` all need root. Options, in order of preference:

1. A small root-owned helper `/usr/local/bin/powermode-root`, called through a polkit rule for the active local user, with no password prompt.
2. A sudoers entry limited to that helper.

The helper must only accept the three mode names and nothing else. The user-side script handles brightness, notifications and `powerprofilesctl`.

### Mode transitions

- **To eco:** stop apps using the dGPU (warn if `fuser /dev/nvidia*` shows users other than Hyprland), stop `nvidia-powerd`, unload `nvidia_drm`, `nvidia_modeset`, `nvidia_uvm`, `nvidia`, then write `1` to `/sys/bus/pci/devices/0000:c4:00.0/remove`. Do the same for `c4:00.1` (the audio function). Save brightness, then lower it.
- **From eco:** run `echo 1 > /sys/bus/pci/rescan`, load nvidia, restore brightness. If the rescan does not bring the card back (the rail was cut), fall back to a clear error telling the user a reboot is needed. This has to be tested before relying on it.
- **To pwr:** set runtime PM to `on`. Hyprland as primary on the dGPU cannot be done live, so update a state file that `env.lua` reads at start and notify "Restart Hyprland to make the dGPU primary". Until then the dGPU is awake but offload-only.
- **Dyn is the default.** It must not hold the dGPU open, so Hyprland has to be on the iGPU for the card to actually sleep.

## Noctalia bar item

Noctalia 5.4.1 is installed, with the widget lists defined in `config.toml` under `[bar.top]`. How v5 supports custom widgets is not confirmed yet, so the first step is to find out. In order of preference:

1. A native Noctalia plugin or script widget, if v5 supports one. Show the mode text (`eco`, `dyn`, `pwr`) plus an icon, and run a script on click.
2. If v5 has no custom widget, use a popup menu. A command like `wofi --dmenu` or the Noctalia launcher in dmenu mode, opened from a Hyprland keybind, would replace the click.
3. Polling a state file and showing it via an existing widget is a last resort.

Display:
- Text: `eco` / `dyn` / `pwr`.
- Color or icon varies by mode: leaf, balance, bolt. Colors come from Noctalia's theme.
- Left click: open the picker with the three modes. The current one is marked.
- Selecting one runs `powermode set <mode>` and shows a notification with the result.
- Refresh: watch `~/.local/state/powermode` (inotify) so changes made from the terminal or a keybind show up immediately.

Also add a Hyprland keybind to cycle modes, for example on the ROG key (`XF86Launch1`) or `SUPER + P`, so the bar is not the only way in.

## Dependencies

- `asusd` (installed, running), `power-profiles-daemon` (installed by the GPU setup script), `brightnessctl` (installed), `nvidia-powerd` (enabled by the same script).
- `polkit` (the `hyprpolkitagent` is already used by the session).

## Risks and open questions

- **dGPU return after removal:** Whether PCI rescan restores the card after a remove is unproven on this firmware. The earlier BIOS fault left the power rail cut, and that must not happen here. Test manually before wiring it in.
- **Hyprland on the dGPU (pwr):** Needs a restart, and the laptop display is wired to the iGPU. Rendering on the dGPU and copying frames across costs power and can cause flicker or lag. It may be better for `pwr` to keep the iGPU primary and just keep the dGPU awake for offload. Decide after testing.
- **Mode switching while apps use the dGPU:** Browser or game processes may block the module unload. The script should list the blocking processes rather than kill them.
- **Hardware video decode:** Works from the iGPU through VA-API (`libva-mesa-driver`), so eco and dyn lose nothing there.
- **Noctalia v5 extension API:** Unconfirmed. Check the docs or source before choosing between options 1 to 3 above.
- **Persistence of fan curves** across `asusd` restarts needs checking.
- **`AQ_DRM_DEVICES` format:** The variable is colon-separated. A `/dev/dri/by-path/pci-0000\:c5\:00.0-card` value (with escaped colons) made Hyprland exit at startup. The fix is a plain `/dev/dri/cardN` path, resolved at startup from the by-path symlink (see `~/.config/hypr/lua/env.lua`). Card numbers are not stable between boots: `card0` was the AMD iGPU on one boot and the NVIDIA card on the next. A fixed udev symlink such as `/dev/dri/igpu` would be more robust.
- **Mode switching must not break Hyprland startup:** `powermode` must write only valid, tested values into anything `env.lua` reads. A bad value there stops the compositor from starting, so validate before writing and keep a fallback.
- **dGPU power control after boot:** After the udev rule change, `c4:00.0/power/control` reads `auto`. Whether it actually reaches `suspended` once Hyprland stops holding it still needs checking after the next login.
- **Display wiring:** Confirm that external ports (HDMI, USB-C DP) are driven by the iGPU, not the dGPU. If any is dGPU-driven, `eco` (dGPU removed) disables that output.
- **Unverified hardware video decode:** `libva-utils` is not installed, so VA-API on the iGPU has not been verified with `vainfo`.

## Out of scope

- Display refresh-rate switching (panel is 60 Hz).
- Windows or dual-boot behavior.
- DialPad and 2-in-1 work, which is tracked separately.
