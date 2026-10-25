from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import plistlib

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

def background(size, color):
    return Image.new("RGB", (size, size), color)

icon_path = APP / "Assets.xcassets/AppIcon.appiconset/AppIcon-512@2x.png"
icon_path.parent.mkdir(parents=True, exist_ok=True)
icon = background(1024, (29, 29, 31))
d = ImageDraw.Draw(icon)
d.text((512, 485), "一", font=font(350), fill=(245, 245, 247), anchor="mm")
d.text((512, 795), "MOMENT", font=font(36, True), fill=(124, 184, 124), anchor="mm")
icon.save(icon_path)

splash_dir = APP / "Assets.xcassets/Splash.imageset"
splash_dir.mkdir(parents=True, exist_ok=True)
splash = background(2732, (242, 242, 242))
d = ImageDraw.Draw(splash)
d.text((1366, 1240), "一刻", font=font(300), fill=(29, 29, 31), anchor="mm")
d.text((1366, 1555), "MOMENT", font=font(58, True), fill=(65, 125, 84), anchor="mm")
d.text((1366, 1760), "每一刻，都清晰。", font=font(64), fill=(110, 110, 115), anchor="mm")
for name in ["splash-2732x2732-1.png", "splash-2732x2732-2.png", "splash-2732x2732.png"]:
    splash.save(splash_dir / name)

info_path = APP / "Info.plist"
info = plistlib.loads(info_path.read_bytes())
info.update({
    "CFBundleShortVersionString": "1.1.0",
    "CFBundleVersion": "2",
    "NSCameraUsageDescription": "拍摄照片或视频，保存到你的时刻。",
    "NSMicrophoneUsageDescription": "录制语音，保存到你的时刻。",
    "NSPhotoLibraryUsageDescription": "选择照片和视频，添加到你的时刻。",
    "NSPhotoLibraryAddUsageDescription": "保存你在时刻中查看的照片或视频。",
})
info_path.write_bytes(plistlib.dumps(info, fmt=plistlib.FMT_XML, sort_keys=False))
print("一刻 1.1 iOS assets and permissions configured")
