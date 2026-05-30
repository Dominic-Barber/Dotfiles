import sys
import time
import colorsys
from openrgb import OpenRGBClient
from openrgb.utils import RGBColor

# 1. Grab colors from arguments
hex_primary = sys.argv[1]
hex_tertiary = sys.argv[2]

def boost_color(hex_in):
    hex_in = hex_in.lstrip('#')
    r, g, b = tuple(int(hex_in[i:i+2], 16)/255.0 for i in (0, 2, 4))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    r, g, b = colorsys.hls_to_rgb(h, 0.5, 1.0)
    return RGBColor(int(r*255), int(g*255), int(b*255))

P = boost_color(hex_primary)
T = boost_color(hex_tertiary)

# 2. Connect to the OpenRGB SDK Server
client = OpenRGBClient()
fan_controller = client.devices[1]

# Force direct mode just in case it reverted
try:
    fan_controller.set_mode('direct')
except Exception:
    pass


fan_controller.zones[0].set_colors([P] * len(fan_controller.zones[0].leds))

# 3. Build frames for ALL zones dynamically
# range(len(...)) grabs every single zone on the device, whether it's 0, 1, 2, or 3.
zone_frames = {}
for z_idx in range(len(fan_controller.zones)):
    num_leds = len(fan_controller.zones[z_idx].leds)
    
    # Skip dummy zones that have 0 LEDs configured
    if num_leds == 0:
        continue
        
    frames = []
    for i in range(num_leds):
        # Start with a base of Primary
        frame = [P] * num_leds
        
        # Apply 30/70 blend to the current index and neighbors
        for offset in [-1, 0, 1]:
            idx = (i + offset) % num_leds
            r = int(T.red * 0.3 + P.red * 0.7)
            g = int(T.green * 0.3 + P.green * 0.7)
            b = int(T.blue * 0.3 + P.blue * 0.7)
            frame[idx] = RGBColor(r, g, b)
            
        frames.append(frame)
    zone_frames[z_idx] = frames

print(f"Loaded {len(zone_frames)} active zones on device '{fan_controller.name}'. Starting loop...")

# 4. Fast Loop
tick = 0
try:
    while True:
        for z_idx, frames in zone_frames.items():
            current_frame = frames[tick % len(frames)]
            fan_controller.zones[z_idx].set_colors(current_frame)
        
        # Explicitly push the buffer to the physical hardware
        fan_controller.show()
        
        tick += 1
        time.sleep(0.05)
except KeyboardInterrupt:
    pass
