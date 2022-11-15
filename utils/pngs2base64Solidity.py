import os
import sys
import glob
import base64

assert len(sys.argv) > 2, "Provide path to PNG directory (ending in /) or file basename as cli arg"

image_dir = sys.argv[1]
out_path = sys.argv[2]

encoded_pngs = ''

for png in glob.glob(image_dir + '*.png'):
    with open(png, 'rb') as png_file:
        encoded = base64.b64encode(png_file.read()).decode('ascii')
    png_name = os.path.basename(png).split('.')[0]
    encoded_pngs += '\n// ' + png_name
    encoded_pngs += '\n"' + encoded
    encoded_pngs += '"'

with open(out_path, 'w') as out_file:
    out_file.write(encoded_pngs)
