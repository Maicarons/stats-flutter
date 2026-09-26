"""Render splash logo (bars + normal curve) to app icon PNGs."""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(r"F:\workspace\stats-flutter\assets\icon\app_icon.png")
OUT.parent.mkdir(parents=True, exist_ok=True)

W = 1024
BLUE = (47, 111, 237, 255)       # #2F6FED
CYAN = (92, 225, 230, 255)       # #5CE1E6
WHITE = (255, 255, 255, 255)

# Background: blue rounded square (full bleed, for adaptive icon / launcher)
img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

# rounded square bg
pad = 0
radius = W * 0.22
d.rounded_rectangle([pad, pad, W - pad, W - pad], radius=radius, fill=BLUE)

# inner white card (like splash)
# splash: container 112 with padding 18 on 112 => logo area is ~76/112 of white box
# For icon we draw white rounded rect then logo inside
card_m = W * 0.12
card_r = W * 0.14
d.rounded_rectangle(
    [card_m, card_m, W - card_m, W - card_m],
    radius=card_r,
    fill=WHITE,
)

# Logo drawing area = content of white card (like splash padding 18/112)
# Splash: white 112, padding 18 => painter size 76x76
# We map painter coords to inner area
inner_l = card_m + W * 0.04
inner_t = card_m + W * 0.04
inner_r = W - card_m - W * 0.04
inner_b = W - card_m - W * 0.04
iw = inner_r - inner_l
ih = inner_b - inner_t

def bar(x, top, color):
    # (x, top, color) fractions of painter size
    bx = inner_l + x * iw
    by = inner_t + top * ih
    bw = 0.16 * iw
    bh = (0.88 - top) * ih
    d.rounded_rectangle([bx, by, bx + bw, by + bh], radius=iw * 0.04, fill=color)

bar(0.12, 0.42, BLUE)
bar(0.42, 0.30, BLUE)
bar(0.72, 0.18, CYAN)

# cubic curve like CustomPainter: (0.10,0.48) C (0.30,0.28) (0.55,0.16) (0.92,0.12)
# sample cubic bezier
p0 = (0.10, 0.48)
p1 = (0.30, 0.28)
p2 = (0.55, 0.16)
p3 = (0.92, 0.12)

def cubic(t):
    u = 1 - t
    x = u**3 * p0[0] + 3 * u**2 * t * p1[0] + 3 * u * t**2 * p2[0] + t**3 * p3[0]
    y = u**3 * p0[1] + 3 * u**2 * t * p1[1] + 3 * u * t**2 * p2[1] + t**3 * p3[1]
    return x, y

pts = []
N = 80
for i in range(N + 1):
    x, y = cubic(i / N)
    pts.append((inner_l + x * iw, inner_t + y * ih))

# stroke curve
width = int(iw * 0.042)
if width < 2:
    width = 2
d.line(pts, fill=CYAN, width=width, joint="curve")
# round caps
for cx, cy in (pts[0], pts[-1]):
    r = width / 2
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=CYAN)

img.save(OUT, "PNG")
print("saved", OUT, img.size)

# Also save a smaller preview
img.resize((256, 256), Image.Resampling.LANCZOS).save(
    OUT.with_name("app_icon_256.png"), "PNG"
)
print("preview saved")
