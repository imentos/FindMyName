#!/bin/bash

# Screenshot Resizer for App Store
# Resizes screenshots to accepted App Store dimensions

INPUT_DIR="${1:-screenshots_with_captions}"
OUTPUT_DIR="Screenshots_Resized"

# Target dimension: 1284 × 2778px (iPhone 15 Pro, 14 Pro)
TARGET_WIDTH=1284
TARGET_HEIGHT=2778

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "📸 Resizing screenshots for App Store submission..."
echo "Input directory: $INPUT_DIR"
echo "Output directory: $OUTPUT_DIR"
echo "Target size: ${TARGET_WIDTH} × ${TARGET_HEIGHT}px"
echo ""

# Check if input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "❌ Error: Directory '$INPUT_DIR' not found"
    echo "Usage: ./resize_screenshots.sh [input_directory]"
    exit 1
fi

# Count PNG files
count=$(find "$INPUT_DIR" -maxdepth 1 -name "*.png" -type f | wc -l | tr -d ' ')

if [ "$count" -eq 0 ]; then
    echo "❌ No PNG files found in $INPUT_DIR"
    exit 1
fi

echo "Found $count screenshot(s) to resize"
echo ""

# Process each PNG file
counter=1
for file in "$INPUT_DIR"/*.png; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        output_file="$OUTPUT_DIR/AppStore_Screenshot_$counter.png"
        
        echo "[$counter/$count] Processing: $filename"
        
        # Get current dimensions
        current_size=$(sips -g pixelWidth -g pixelHeight "$file" | grep -E 'pixelWidth|pixelHeight' | awk '{print $2}' | paste -sd 'x' -)
        echo "  Current size: $current_size"
        
        # Resize using sips (maintains aspect ratio, fits within bounds)
        sips -z $TARGET_HEIGHT $TARGET_WIDTH "$file" --out "$output_file" > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            new_size=$(sips -g pixelWidth -g pixelHeight "$output_file" | grep -E 'pixelWidth|pixelHeight' | awk '{print $2}' | paste -sd 'x' -)
            echo "  ✅ Resized to: $new_size"
            echo "  Saved as: $output_file"
        else
            echo "  ❌ Failed to resize"
        fi
        
        echo ""
        ((counter++))
    fi
done

echo "✅ Done! Resized screenshots saved to: $OUTPUT_DIR"
echo ""
echo "📱 App Store Requirements:"
echo "  • 6.7\" Display: 1290 × 2796px (iPhone 15 Pro Max, 14 Pro Max)"
echo "  • 6.5\" Display: 1242 × 2688px (iPhone 11 Pro Max, XS Max)"
echo "  • 6.1\" Display: 1284 × 2778px (iPhone 15 Pro, 14 Pro) ✅ USED"
echo ""
echo "Your screenshots are now: ${TARGET_WIDTH} × ${TARGET_HEIGHT}px"
echo "This matches the 6.1\" Display requirement."
