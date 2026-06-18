import numpy as np
import matplotlib.pyplot as plt

# 1. Settings (Match your params.v)
width = 64  
height = 64

# 2. Load the hex data
try:
    with open("framebuffer_dump.hex", "r") as f:
        # Read lines and remove any 'h' or whitespace
        hex_data = [line.strip().replace('h', '') for line in f if line.strip()]
    
    # 3. Convert hex strings to integers
    pixels = [int(val, 16) for val in hex_data]

    # 4. Reshape into an image grid
    # If the file has 4096 values, it's 64x64
    image_array = np.array(pixels).reshape((height, width))

    # 5. Display
    plt.figure(figsize=(6,6))
    plt.imshow(image_array, cmap='magma') # 'magma' or 'hot' looks cool for GPUs
    plt.title("Hardware Rasterizer Output")
    plt.axis('off') # Hide pixel coordinates
    plt.show()

except Exception as e:
    print(f"Error: {e}")
    print("Make sure framebuffer_dump.hex exists and has 4096 values.")