from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import plistlib
import random

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "ios/App/App"

def font(size, latin=False):
    candidates = ["/System/Library/Fonts/Helvetica.ttc"] if latin else [
        "/System/Library/Fonts/PingFang.ttc",
        "/System/Library/Fonts/STHeiti Light.ttc",
        "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
    ]
    for candidate in candidates:
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default(size=size)

def background(size):
    image = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(image)
    for y in range(size):
        t = y / max(1, size - 1)
        draw.line((0, y, size, y), fill=(int(15-10*t), int(23-17*t), int(42+3*t)))
    rng = random.Random(20261026)
    for _ in range(int(size * .12)):
        x, y = rng.randrange(size), rng.randrange(size)
        r = rng.choice([1, 1, 2, 2, 3]) * max(1, size // 1024)
        color = rng.choice([(235,245,255), (155,216,201), (182,192,208)])
        draw.ellipse((x-r, y-r, x+r, y+r), fill=color)
    return image

icon_path = APP / "Assets.xcassets/AppIcon.appiconset/AppIcon-512@2x.png"
icon_path.parent.mkdir(parents=True, exist_ok=True)
icon = background(1024)
d = ImageDraw.Draw(icon)
d.ellipse((228,228,796,796), outline=(98,142,151), width=4)
d.ellipse((274,274,750,750), outline=(58,87,111), width=2)
d.text((512,495), "一", font=font(330), fill=(248,250,252), anchor="mm")
d.text((512,805), "MOMENT", font=font(35, True), fill=(155,216,201), anchor="mm")
icon.save(icon_path)

splash_dir = APP / "Assets.xcassets/Splash.imageset"
splash_dir.mkdir(parents=True, exist_ok=True)
splash = background(2732)
d = ImageDraw.Draw(splash)
d.ellipse((866,806,1866,1806), outline=(64,101,117), width=6)
d.text((1366,1240), "一刻", font=font(300), fill=(248,250,252), anchor="mm")
d.text((1366,1555), "MOMENT", font=font(58, True), fill=(155,216,201), anchor="mm")
d.text((1366,1760), "每一刻，都清晰。", font=font(64), fill=(182,192,208), anchor="mm")
for name in ["splash-2732x2732-1.png", "splash-2732x2732-2.png", "splash-2732x2732.png"]:
    splash.save(splash_dir / name)

info_path = APP / "Info.plist"
info = plistlib.loads(info_path.read_bytes())
info.update({
    "CFBundleShortVersionString": "1.0.0",
    "CFBundleVersion": "1",
    "NSCameraUsageDescription": "拍摄照片或视频，保存到你的时刻。",
    "NSMicrophoneUsageDescription": "录制语音，保存到你的时刻。",
    "NSPhotoLibraryUsageDescription": "选择照片和视频，添加到你的时刻。",
    "NSPhotoLibraryAddUsageDescription": "保存你在时刻中查看的照片或视频。",
})
info_path.write_bytes(plistlib.dumps(info, fmt=plistlib.FMT_XML, sort_keys=False))
print("一刻 iOS assets and media permissions configured")
