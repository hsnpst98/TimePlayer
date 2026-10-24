import os, math, json
from PIL import Image, ImageDraw

S = 2048
img = Image.new("RGB", (S, S))
d = ImageDraw.Draw(img)
top, bot = (58, 36, 102), (8, 6, 13)
for y in range(S):
    t = y / (S - 1)
    c = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3))
    d.line([(0, y), (S, y)], fill=c)

img = img.convert("RGBA")
ov = Image.new("RGBA", (S, S), (0, 0, 0, 0))
o = ImageDraw.Draw(ov)
cx = cy = S / 2

h = int(S * 0.55)
for y in range(h):
    o.line([(0, y), (S, y)], fill=(255, 255, 255, int(60 * (1 - y / h))))

R, n = S * 0.33, 60
for i in range(n):
    a = math.radians(i * 360 / n - 90)
    x1, y1 = cx + math.cos(a) * (R - S * 0.035), cy + math.sin(a) * (R - S * 0.035)
    x2, y2 = cx + math.cos(a) * (R + S * 0.035), cy + math.sin(a) * (R + S * 0.035)
    col = (192, 139, 255, 255) if i < n / 4 else (255, 255, 255, 90)
    o.line([(x1, y1), (x2, y2)], fill=col, width=int(S * 0.012))

r = S * 0.2
o.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 255, 255, 30),
          outline=(255, 255, 255, 100), width=int(S * 0.006))
o.polygon([(cx - S * 0.09, cy - S * 0.13), (cx - S * 0.09, cy + S * 0.13),
           (cx + S * 0.13, cy)], fill=(255, 255, 255, 255))

img = Image.alpha_composite(img, ov).convert("RGB").resize((1024, 1024), Image.LANCZOS)

base = "Sources/Assets.xcassets"
icon = base + "/AppIcon.appiconset"
os.makedirs(icon, exist_ok=True)
img.save(icon + "/icon.png")
info = {"author": "xcode", "version": 1}
json.dump({"info": info}, open(base + "/Contents.json", "w"))
json.dump({"images": [{"filename": "icon.png", "idiom": "universal",
                       "platform": "ios", "size": "1024x1024"}],
           "info": info}, open(icon + "/Contents.json", "w"))
