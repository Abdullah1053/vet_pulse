import os
from PIL import Image, ImageDraw

source_path = 'assets/images/app_icon_colorful.jpg'
res_base = 'android/app/src/main/res'

sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

if not os.path.exists(source_path):
    print(f"Error: {source_path} not found")
    exit(1)

src = Image.open(source_path).convert('RGBA')

for folder, size in sizes.items():
    target_dir = os.path.join(res_base, folder)
    os.makedirs(target_dir, exist_ok=True)

    # 1. Standard square/squircle icon with Lanczos resampling
    resized = src.resize((size, size), Image.Resampling.LANCZOS)
    icon_path = os.path.join(target_dir, 'ic_launcher.png')
    resized.save(icon_path, 'PNG', optimize=True)

    # 2. Circular icon for android:roundIcon
    mask = Image.new('L', (size * 4, size * 4), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, size * 4 - 1, size * 4 - 1), fill=255)
    mask = mask.resize((size, size), Image.Resampling.LANCZOS)

    round_icon = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    round_icon.paste(resized, (0, 0), mask=mask)

    round_path = os.path.join(target_dir, 'ic_launcher_round.png')
    round_icon.save(round_path, 'PNG', optimize=True)

    print(f"Generated {folder}: ic_launcher.png & ic_launcher_round.png ({size}x{size})")

print("All Android launcher icons generated successfully!")
