#!/usr/bin/env python3
"""生成一刻 App 图标：深灰黑底 + 白色「一」字横线，1024x1024。"""
from PIL import Image, ImageDraw

SIZE = 1024
BG = (28, 28, 30, 255)
MARK = (245, 245, 247, 255)

img = Image.new("RGBA", (SIZE, SIZE), BG)
d = ImageDraw.Draw(img)

w, h = int(SIZE * 0.46), int(SIZE * 0.09)
x0 = (SIZE - w) // 2
y0 = (SIZE - h) // 2
d.rounded_rectangle([x0, y0, x0 + w, y0 + h], radius=h // 2, fill=MARK)

img.save("YikeMoment/YikeMoment/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
print("icon generated")
