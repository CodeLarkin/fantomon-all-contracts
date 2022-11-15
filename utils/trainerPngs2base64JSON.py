import sys
import base64

CARDS = [
    "Common1",
    "Common2",
    "Common3",
    "Common4",
    "Common5",
    "Common6",
    "Common7",
    "Rare1",
    "Rare2",
    "Rare3",
    "Rare4",
    "Rare5",
    "Rare6",
    "Rare7",
    "Epic1",
    "Epic2",
    "Epic3",
    "Epic4",
    "Epic5",
    "Epic6",
    "Epic7",
    "Legendary1",
    "Legendary2",
    "Legendary3",
    "Legendary4",
    "Legendary5",
    "Legendary6",
    "Legendary7",
]

assert len(sys.argv) > 2, "Provide path to PNG directory (ending in /) as cli arg"

image_dir = sys.argv[1]
out_dir = sys.argv[2]


TOTAL = len(CARDS)

json_str = "["

for idx, card in enumerate(CARDS):

    png = image_dir + '/' + card + '.png'
    with open(png, 'rb') as png_file:
        encoded_png = base64.b64encode(png_file.read()).decode('ascii')
    json_str += '\n    "data:image/png;base64,' + encoded_png + '"'
    if idx != TOTAL-1:
        json_str += ','

json_str += '\n]'

with open(out_dir + '/trainersBase64.json', 'w') as out_file:
    out_file.write(json_str)
