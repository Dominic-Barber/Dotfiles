#!/bin/bash

source ~/.cache/noctalia/openrgb_colors.sh

# Python function to mute colors (reduce lightness and saturation) for UI
mute_color() {
  python3 -c "
import sys, colorsys
hex_in = sys.argv[1].lstrip('#')
max_l = float(sys.argv[2])
max_s = float(sys.argv[3])
r, g, b = tuple(int(hex_in[i:i+2], 16)/255.0 for i in (0, 2, 4))
h, l, s = colorsys.rgb_to_hls(r, g, b)
l = min(l, max_l)
s = min(s, max_s)
r, g, b = colorsys.hls_to_rgb(h, l, s)
print(f'#{int(r*255):02X}{int(g*255):02X}{int(b*255):02X}')
" "$1" "$2" "$3"
}

# Generate our unified UI colors
ZEN_PRIMARY=$(mute_color "$RGB_PRIMARY" 0.6 0.6)
ZEN_BG=$(mute_color "$RGB_SECONDARY" 0.12 0.2)
ZEN_SURFACE=$(mute_color "$RGB_TERTIARY" 0.18 0.15) # Muted tertiary for tab cards

# ZEN-WABI INTEGRATION:
# Write matugen-vars.json for fx-autoconfig hot-reloading
python3 << 'PYEOF'
import sys, colorsys, json, os

def hex_to_hls(h):
    h = h.lstrip('#')
    r,g,b = tuple(int(h[i:i+2],16)/255.0 for i in (0,2,4))
    return colorsys.rgb_to_hls(r,g,b)

def hls_to_hex(h,l,s):
    r,g,b = colorsys.hls_to_rgb(h,l,s)
    return f'#{int(r*255):02X}{int(g*255):02X}{int(b*255):02X}'

primary  = os.environ.get('RGB_PRIMARY', '#b0c6ff')
secondary = os.environ.get('RGB_SECONDARY', '#c0c6dc')
tertiary  = os.environ.get('RGB_TERTIARY', '#e0bbde')

h,l,s = hex_to_hls(primary)
bg        = hls_to_hex(h, 0.06, min(s,0.15)) + '40' # 25% opacity
bg_dark   = hls_to_hex(h, 0.11, min(s,0.12)) + '40'
bg_light  = hls_to_hex(h, 0.18, min(s,0.18)) + '40'
fg        = hls_to_hex(h, 0.88, min(s,0.15))
fg_light  = hls_to_hex(h, 0.65, min(s,0.12))
ah,_,as_ = hex_to_hls(primary)
accent    = hls_to_hex(ah, 0.65, min(as_,0.85))
sh,_,ss  = hex_to_hls(secondary)
secondary_out = hls_to_hex(sh, 0.60, min(ss,0.75))
th,_,ts  = hex_to_hls(tertiary)
tertiary_out  = hls_to_hex(th, 0.55, min(ts,0.70))

vars_json = {
    'bg': bg, 'bg-dark': bg_dark, 'bg-light': bg_light,
    'fg': fg, 'fg-light': fg_light,
    'accent': accent, 'secondary': secondary_out, 'tertiary': tertiary_out
}

profile_chrome = os.path.expanduser("~/.config/zen/t7pvbxrk.Default (release)/chrome")
json_path = os.path.join(profile_chrome, 'matugen-vars.json')

try:
    with open(json_path, 'w') as f:
        json.dump(vars_json, f, indent=2)
except Exception as e:
    pass

# Generate web content transparency override
web_bg = hls_to_hex(h, 0.06, min(s,0.15)) + 'CC' # 90% opacity (solid enough for reading, still transparent)
web_css = f"""
:root {{
    background-color: transparent !important;
}}
body {{
    background-color: {web_bg} !important;
}}
"""
userstyles_path = os.path.join(profile_chrome, 'matugen-userstyles.css')
try:
    with open(userstyles_path, 'w') as f:
        f.write(web_css)
except Exception as e:
    pass
PYEOF

# RGB Sync

# Wait for the OpenRGB server to bind to its port and finish probing
while ! bash -c "echo > /dev/tcp/127.0.0.1/6742" 2>/dev/null; do
  sleep 1
done
# Give it a small buffer after the port binds to ensure devices are loaded
sleep 1


# Python function to max out saturation for static LEDs
boost_color() {
  python3 -c "
import sys, colorsys
hex_in = sys.argv[1].lstrip('#')
r, g, b = tuple(int(hex_in[i:i+2], 16)/255.0 for i in (0, 2, 4))
h, l, s = colorsys.rgb_to_hls(r, g, b)
r, g, b = colorsys.hls_to_rgb(h, 0.5, 1.0)
print(f'{int(r*255):02X}{int(g*255):02X}{int(b*255):02X}')
" "$1"
}

SECONDARY=$(boost_color "$RGB_SECONDARY")
TERTIARY=$(boost_color "$RGB_TERTIARY")

# Kill any existing dynamic fan loops (Python version)
pkill -f "rgb_fan_loop.py"

# Push static colors to GPU, Mouse, and Motherboard Bar
openrgb \
  -d 0 -m direct -c "$TERTIARY" \
  -d 1 -z 0 -m direct -c "$TERTIARY" \
  -d 2 -m direct -c "$TERTIARY"

# Launch the persistent Python daemon for the fast fan chase
nohup python3 /home/barberdj/.config/hypr/scripts/rgb_fan_loop.py "$RGB_PRIMARY" "$RGB_TERTIARY" > /dev/null 2>&1 & disown
