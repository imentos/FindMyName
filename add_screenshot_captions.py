#!/usr/bin/env python3
"""
Add promotional captions above App Store screenshots with iPhone frame
Emphasizes time-saving and instant name finding for swim meet parents
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Configuration
SCREENSHOTS_DIR = "screenshots"
OUTPUT_DIR = "screenshots_with_captions"
TITLE_FONT_SIZE = 90
SUBTITLE_FONT_SIZE = 70
DESC_FONT_SIZE = 55
CAPTION_COLOR = (0, 0, 0)  # Black text
BACKGROUND_COLOR = (204, 204, 204)  # Light gray background #cccccc
CAPTION_HEIGHT = 400  # Space for captions above image
PADDING = 30
SCREENSHOT_SCALE = 1.0  # Keep original screenshot size
PHONE_FRAME_COLOR = (30, 30, 30)  # Dark gray/black phone frame
FRAME_THICKNESS = 12
CORNER_RADIUS = 50
NOTCH_WIDTH = 200
NOTCH_HEIGHT = 30

# Your 5 screenshot captions for Find My Name
CAPTIONS = [
    {
        "title": "From This to This in 3 Seconds",
        "subtitle": "Instant Name Search",
        "description": "Point your camera at any crowded name board"
    },
    {
        "title": "Never Miss a Heat Again",
        "subtitle": "Real-Time OCR Scanning",
        "description": "Find your child's name instantly on heat sheets"
    },
    {
        "title": "Works on Any Event Board",
        "subtitle": "Swim Meets • Track • Sports",
        "description": "Scan rosters, lineups, and heat sheets offline"
    },
    {
        "title": "Save Your Favorite Names",
        "subtitle": "Quick Access",
        "description": "Search multiple names with one tap"
    }
]

def get_font(size):
    """Try to get Apple SF Pro or system font"""
    font_paths = [
        "/System/Library/Fonts/SF-Pro-Display-Bold.otf",
        "/System/Library/Fonts/SF-Pro-Display-Semibold.otf",
        "/System/Library/Fonts/SF-Pro.ttf",
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/SFNSDisplay.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    
    for font_path in font_paths:
        try:
            return ImageFont.truetype(font_path, size)
        except:
            continue
    return ImageFont.load_default()

def create_captioned_image(screenshot_path, caption_data):
    """Create new image with captions above screenshot - same size as original"""
    # Open screenshot (keep original size)
    screenshot = Image.open(screenshot_path)
    
    # Keep original total dimensions
    new_width = screenshot.width
    total_height = screenshot.height
    
    # Crop screenshot to fit within original height minus caption space
    screenshot_crop_height = total_height - CAPTION_HEIGHT
    screenshot_resized = screenshot.crop((0, 0, new_width, screenshot_crop_height))
    
    # Create final image same size as original
    final_image = Image.new('RGB', (new_width, total_height), BACKGROUND_COLOR)
    
    # Draw captions on top portion
    draw = ImageDraw.Draw(final_image)
    
    # Get fonts - use title field instead of subtitle
    title_font = get_font(TITLE_FONT_SIZE)
    
    # Draw title in the top caption area (centered)
    title_bbox = draw.textbbox((0, 0), caption_data["title"], font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    title_height = title_bbox[3] - title_bbox[1]
    title_x = (new_width - title_width) // 2
    title_y = (CAPTION_HEIGHT - title_height) // 2  # Centered in caption area
    
    # Draw text
    draw.text((title_x, title_y), caption_data["title"], 
              fill=(0, 0, 0), font=title_font)  # Black text
    
    # Paste screenshot below the caption area
    final_image.paste(screenshot_resized, (0, CAPTION_HEIGHT))
    
    return final_image

def process_screenshots():
    """Process all screenshots"""
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    screenshots = sorted([f for f in os.listdir(SCREENSHOTS_DIR) 
                         if f.lower().endswith(('.png', '.jpg', '.jpeg'))])
    
    print(f"Found {len(screenshots)} screenshot(s)\n")
    
    for i, screenshot_file in enumerate(screenshots[:5]):
        input_path = os.path.join(SCREENSHOTS_DIR, screenshot_file)
        output_path = os.path.join(OUTPUT_DIR, f"screenshot_{i+1}_captioned.png")
        
        print(f"Processing {screenshot_file}...")
        
        captioned_image = create_captioned_image(input_path, CAPTIONS[i])
        captioned_image.save(output_path, 'PNG', quality=95)
        
        print(f"✓ Saved to {output_path}")
        print(f"  Size: {captioned_image.width}x{captioned_image.height}px\n")
    
    print(f"✅ Done! Captioned screenshots saved to '{OUTPUT_DIR}/' directory")

if __name__ == "__main__":
    print("Find My Name Screenshot Caption Generator")
    print("=" * 50)
    print(f"Looking for screenshots in '{SCREENSHOTS_DIR}/' directory...\n")
    
    if not os.path.exists(SCREENSHOTS_DIR):
        print(f"❌ '{SCREENSHOTS_DIR}/' directory not found!")
        print(f"\nCreate it and add your 5 screenshots:")
        print(f"  mkdir {SCREENSHOTS_DIR}")
        print("\nScreenshot order:")
        for i, caption in enumerate(CAPTIONS, 1):
            print(f"  {i}. {caption['title']}")
    else:
        process_screenshots()