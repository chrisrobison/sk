#!/bin/bash

# Script to create a spritesheet of all mouth images from mouths.json plus default.png

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

# Determine a reasonable grid size (try to make it approximately square)
GRID_SIZE=$(echo "scale=0; sqrt($IMAGE_COUNT)" | bc)
GRID_WIDTH=$((GRID_SIZE + 1))  # Add a bit more width to make it more rectangular
GRID_HEIGHT=$((($IMAGE_COUNT + $GRID_WIDTH - 1) / $GRID_WIDTH))

echo "Creating spritesheet with grid: ${GRID_WIDTH}x${GRID_HEIGHT}"

# Create the spritesheet
montage $IMAGES -background transparent -tile ${GRID_WIDTH}x${GRID_HEIGHT} -geometry +5+5 mouths_spritesheet.png

# Create a CSS sprite map file
echo "Creating CSS sprite map file..."
cat > mouth_sprites.css << EOF
/* Mouth Sprites CSS
 * Generated: $(date)
 * Grid: ${GRID_WIDTH}x${GRID_HEIGHT}
 */

.mouth-sprite {
  background-image: url('mouths_spritesheet.png');
  background-repeat: no-repeat;
  display: inline-block;
}
EOF

# Get spritesheet dimensions
SPRITESHEET_INFO=$(identify -format "%w %h" mouths_spritesheet.png)
SHEET_WIDTH=$(echo $SPRITESHEET_INFO | cut -d' ' -f1)
SHEET_HEIGHT=$(echo $SPRITESHEET_INFO | cut -d' ' -f2)

echo "Spritesheet dimensions: ${SHEET_WIDTH}x${SHEET_HEIGHT}"

# Create a simple HTML demo page
echo "Creating HTML demo page..."
cat > spritesheet_demo.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Mouth Spritesheet Demo</title>
  <link rel="stylesheet" href="mouth_sprites.css">
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 1200px;
      margin: 0 auto;
      padding: 20px;
    }
    
    .sprite-demo {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 20px;
    }
    
    .sprite-item {
      border: 1px solid #ddd;
      border-radius: 5px;
      padding: 10px;
      text-align: center;
      width: 150px;
    }
    
    h1, h2 {
      color: #333;
    }
    
    .spritesheet-container {
      margin: 20px 0;
      border: 1px solid #ddd;
      padding: 10px;
    }
    
    .spritesheet-container img {
      max-width: 100%;
    }
  </style>
</head>
<body>
  <h1>Mouth Spritesheet Demo</h1>
  
  <div class="spritesheet-container">
    <h2>Complete Spritesheet</h2>
    <img src="mouths_spritesheet.png" alt="Mouth Spritesheet">
  </div>
  
  <h2>Individual Sprites</h2>
  <div class="sprite-demo">
EOF

# Add each image to the demo HTML
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
  pos_x=$((col * (img_width + 5)))
  pos_y=$((row * (img_height + 5)))
  
  # Add CSS class for this sprite
  cat >> mouth_sprites.css << EOF

.mouth-${img_name} {
  width: ${img_width}px;
  height: ${img_height}px;
  background-position: -${pos_x}px -${pos_y}px;
}
EOF

  # Add HTML for this sprite
  cat >> spritesheet_demo.html << EOF
    <div class="sprite-item">
      <div class="mouth-sprite mouth-${img_name}"></div>
      <p>${img_name}</p>
    </div>
EOF

  # Update row and column for next image
  col=$((col + 1))
  if [ $col -eq $GRID_WIDTH ]; then
    col=0
    row=$((row + 1))
  fi
done

# Close HTML file
cat >> spritesheet_demo.html << EOF
  </div>
</body>
</html>
EOF

echo "Done! Created the following files:"
echo "- mouths_spritesheet.png (the spritesheet)"
echo "- mouth_sprites.css (CSS for using the spritesheet)"
echo "- spritesheet_demo.html (demo page showing all sprites)"