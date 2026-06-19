#!/bin/bash

source ~/.cache/noctalia/openrgb_colors.sh

# Wait for the OpenRGB server to bind to its port and finish probing
while ! bash -c "echo > /dev/tcp/127.0.0.1/6742" 2>/dev/null; do
  sleep 1
done
# Give it a small buffer after the port binds to ensure devices are loaded
sleep 1


# Python function to max out saturation for static LEDs (still useful for the bash side)
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
