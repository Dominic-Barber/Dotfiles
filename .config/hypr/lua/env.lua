hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- Render on the AMD iGPU (PCI c5:00.0) so the NVIDIA dGPU can runtime-suspend.
-- Use apps on the dGPU explicitly with `prime-run <app>`.
-- card0/card1 numbering is not stable, so resolve the by-path symlink at startup.
-- (AQ_DRM_DEVICES is colon-separated; by-path names contain colons and break it.)
local igpu = io.popen("readlink -f /dev/dri/by-path/pci-0000:c5:00.0-card 2>/dev/null")
local card = igpu and igpu:read("*l")
if igpu then igpu:close() end
if card and card:match("^/dev/dri/card%d+$") then
    hl.env("AQ_DRM_DEVICES", card)
end
