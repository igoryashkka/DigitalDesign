from PIL import Image
import numpy as np
import os

def convert_txt_to_jpg(txt_file):
    # Extract filename without extension
    base_name = os.path.basename(txt_file).rsplit('.', 1)[0]

    # Read pixel data from text file line by line
    pixel_values = []
    with open(txt_file, "r") as file:
        for line in file:
            line = line.strip()
            pixel_values.extend([int(line[i:i+2], 16) for i in range(0, len(line), 2)])

    # Determine image dimensions from filename
    parts = base_name.split('_')
    if len(parts) >= 3 and parts[-2].isdigit() and parts[-1].isdigit():
        width, height = int(parts[-2]), int(parts[-1])
    else:
        raise ValueError("Invalid filename format. Expected format: filename_width_height.txt")

    # Debugging: Print expected and actual sizes
    expected_size = width * height
    actual_size = len(pixel_values)
    print(f"Expected size: {expected_size}, Actual size: {actual_size}")

    if actual_size != expected_size:
        raise ValueError(f"Size mismatch: expected {expected_size} but got {actual_size}")

    # Reshape data into an image array
    image_array = np.array(pixel_values, dtype=np.uint8).reshape((height, width))

    # Convert to an image and save
    img = Image.fromarray(image_array, mode='L')
    output_file = f"{base_name}.jpg"
    img.save(output_file)
    print(f"Converted {txt_file} to {output_file}")

# Process all .txt files in the current directory
for txt_file in os.listdir():
    if txt_file.endswith(".txt"):
        convert_txt_to_jpg(txt_file)
