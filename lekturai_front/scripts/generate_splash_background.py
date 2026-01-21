#!/usr/bin/env python3
"""
Generate gradient background images for native splash screen.
Requires PIL (Pillow): pip install Pillow
"""

from PIL import Image, ImageDraw
import os

def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple."""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def create_gradient(width, height, colors, stops):
    """Create a gradient image with multiple color stops."""
    image = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(image)
    
    # Calculate diagonal gradient
    for y in range(height):
        for x in range(width):
            # Calculate position along diagonal (0.0 to 1.0)
            position = (x + y) / (width + height)
            
            # Find the two colors to interpolate between
            for i in range(len(stops) - 1):
                if position <= stops[i + 1]:
                    # Interpolate between colors[i] and colors[i+1]
                    local_pos = (position - stops[i]) / (stops[i + 1] - stops[i])
                    r = int(colors[i][0] + (colors[i + 1][0] - colors[i][0]) * local_pos)
                    g = int(colors[i][1] + (colors[i + 1][1] - colors[i][1]) * local_pos)
                    b = int(colors[i][2] + (colors[i + 1][2] - colors[i][2]) * local_pos)
                    break
            else:
                # If we're past the last stop, use the last color
                r, g, b = colors[-1]
            
            draw.point((x, y), fill=(r, g, b))
    
    return image

def main():
    # Create output directory if it doesn't exist
    assets_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'images')
    os.makedirs(assets_dir, exist_ok=True)
    
    # Light mode gradient colors (matches LoadingScreen)
    light_colors = [
        hex_to_rgb('#2563EB'),  # primary
        hex_to_rgb('#3B82F6'),  # primaryLight
        hex_to_rgb('#1E40AF'),  # primaryDark
        hex_to_rgb('#1E3A8A'),  # dark blue
    ]
    light_stops = [0.0, 0.3, 0.7, 1.0]
    
    # Dark mode gradient colors (slightly darker)
    dark_colors = [
        hex_to_rgb('#1E40AF'),  # primaryDark
        hex_to_rgb('#2563EB'),  # primary
        hex_to_rgb('#1E3A8A'),  # dark blue
        hex_to_rgb('#0F172A'),  # very dark blue
    ]
    dark_stops = [0.0, 0.3, 0.7, 1.0]
    
    # Create images at various sizes for different screen densities
    # Using a high resolution that will be scaled down
    width, height = 1080, 1920  # Full HD portrait
    
    print("Generating light mode splash background...")
    light_image = create_gradient(width, height, light_colors, light_stops)
    light_path = os.path.join(assets_dir, 'splash_background.png')
    light_image.save(light_path, 'PNG')
    print(f"Saved: {light_path}")
    
    print("Generating dark mode splash background...")
    dark_image = create_gradient(width, height, dark_colors, dark_stops)
    dark_path = os.path.join(assets_dir, 'splash_background_dark.png')
    dark_image.save(dark_path, 'PNG')
    print(f"Saved: {dark_path}")
    
    print("\nDone! Now run: flutter pub run flutter_native_splash:create")

if __name__ == '__main__':
    main()
