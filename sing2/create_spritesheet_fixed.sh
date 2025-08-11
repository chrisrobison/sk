#!/bin/bash

# Script to create a spritesheet of all mouth images from mouths.json plus default.png
# With improved positioning for the mouth images

# Extract image names from mouths.json
echo "Extracting image names from mouths.json..."
IMAGES=$(grep -o '"image": "[^"]*"' mouths.json | cut -d'"' -f4)

# Add default.png to the list
IMAGES="$IMAGES default.png"

# Remove any duplicates
IMAGES=$(echo "$IMAGES" | tr ' ' '\n' | sort -u | tr '\n' ' ')

# Count total images
IMAGE_COUNT=$(echo "$IMAGES" | wc -w)
echo "Found $IMAGE_COUNT unique mouth images to include in spritesheet."

# Determine a reasonable grid size
GRID_SIZE=$(echo "scale=0; sqrt($IMAGE_COUNT)" | bc)
GRID_WIDTH=$((GRID_SIZE + 1))
GRID_HEIGHT=$((($IMAGE_COUNT + $GRID_WIDTH - 1) / $GRID_WIDTH))

echo "Creating spritesheet with grid: ${GRID_WIDTH}x${GRID_HEIGHT}"

# Create the spritesheet with padding between images
montage $IMAGES -background transparent -tile ${GRID_WIDTH}x${GRID_HEIGHT} -geometry +10+10 mouths_spritesheet.png

# Get spritesheet dimensions
SPRITESHEET_INFO=$(identify -format "%w %h" mouths_spritesheet.png)
SHEET_WIDTH=$(echo $SPRITESHEET_INFO | cut -d' ' -f1)
SHEET_HEIGHT=$(echo $SPRITESHEET_INFO | cut -d' ' -f2)

# Create a CSS sprite map file with correct positions
echo "Creating CSS sprite map file..."
cat > mouth_sprites.css << EOF
/* Mouth Sprites CSS
 * Generated: $(date)
 * Grid: ${GRID_WIDTH}x${GRID_HEIGHT}
 * Spritesheet Size: ${SHEET_WIDTH}x${SHEET_HEIGHT}
 */

.mouth-sprite {
  background-image: url('mouths_spritesheet.png');
  background-repeat: no-repeat;
  display: inline-block;
}
EOF

# Calculate positions for each image
echo "Calculating sprite positions..."
row=0
col=0
for img in $IMAGES; do
  img_name=$(basename "$img" .png)
  echo "Processing $img_name..."
  
  # Get image dimensions
  img_info=$(identify -format "%w %h" "$img")
  img_width=$(echo $img_info | cut -d' ' -f1)
  img_height=$(echo $img_info | cut -d' ' -f2)
  
  # Calculate position in spritesheet
  # We need to account for the padding (10px) between images
  pos_x=$((col * (img_width + 10)))
  pos_y=$((row * (img_height + 10)))
  
  # Add CSS class for this sprite
  cat >> mouth_sprites.css << EOF

.mouth-${img_name} {
  width: ${img_width}px;
  height: ${img_height}px;
  background-position: -${pos_x}px -${pos_y}px;
}
EOF

  # Update row and column for next image
  col=$((col + 1))
  if [ $col -eq $GRID_WIDTH ]; then
    col=0
    row=$((row + 1))
  fi
done

echo "Done! Created updated sprite files."