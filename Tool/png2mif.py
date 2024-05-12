from PIL import Image

# Load the 32 bit depth image
img = Image.open("QRcode.png")

# Convert to 8-bit (3 red, 3 green, 2 blue)
# This is an approximate conversion
img = img.convert("RGB")  # Removes alpha if present

# Create a new image with reduced color depth
new_img = Image.new("P", img.size)
for x in range(img.width):
    for y in range(img.height):
        r, g, b = img.getpixel((x, y))
        # Reduce to RGB332
        r = (r >> 5) << 5
        g = (g >> 5) << 2
        b = b >> 6
        new_color = r | g | b
        new_img.putpixel((x, y), new_color)

width, height = new_img.size
pixels = list(new_img.getdata())

with open('QRcode_RGB332.mif', 'w') as file:
    file.write("WIDTH=8;\n")
    file.write(f"DEPTH={width*height};\n")
    file.write("ADDRESS_RADIX=UNS;\n")
    file.write("DATA_RADIX=UNS;\n")
    file.write("CONTENT\n")
    file.write("BEGIN\n")
    
    for i in range(len(pixels)):
        file.write(f"{i} : {pixels[i]};\n")
    
    file.write("END;\n")
