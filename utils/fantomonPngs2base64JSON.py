import sys
import base64

SPECIES = [
    # AQUA
    "Exotius",
    "Waroda",
    "Flamphy",
    "Buui",
    "Jilius",
    "Octmii",
    "Starfy",
    "Luupe",
    "Milius",
    "Shelfy",  # Ancient

    # CHAOS
    "Ephisto",
    "Kazaaba",  # Ancient

    # COSMIC
    "Xatius",
    "Tapoc",
    "Slusa",
    "Cosmii",

    # DEMON
    "Decro",
    "Merich",
    "Zeepuu",

    # FAIRY
    "Huffly",
    "Munsa",
    "Fenii",
    "Fleppa",
    "Mii",
    "Jixpi",  # Ancient

    # GUNK
    "Kaibu",
    "Koob",
    "Woobek",
    "Googa",
    "Piniju",
    "Gubba",
    "Belkezor",

    # MINERAL
    "Meph",
    "Relixia",  # Ancient

    # PLANT
    "Shrooto",
    "Sphin",
    "Rooto",
    "Icaray",
    "Brutu",
    "Grongel",  # Ancient

    # Starter
    "Larik",  # Aqua
    "Gretto"  # Chaos
]
MORPHS = [
    "MorphedShelfy",   # Ancient
    "MorphedKazaaba",  # Ancient
    "MorphedJixpi",    # Ancient
    "MorphedRelixia",  # Ancient
    "MorphedGrongel"   # Ancient
]

assert len(sys.argv) > 2, "Provide path to PNG directory (ending in /) as cli arg"

image_dir = sys.argv[1]
out_dir = sys.argv[2]


TOTAL = len(SPECIES + MORPHS)

json_str = "["

for idx, species in enumerate(SPECIES + MORPHS):

    png = image_dir + '/' + species + 'Card.png'
    with open(png, 'rb') as png_file:
        encoded_png = base64.b64encode(png_file.read()).decode('ascii')
    json_str += '\n    "data:image/png;base64,' + encoded_png + '"'
    if idx != TOTAL-1:
        json_str += ','

json_str += '\n]'

with open(out_dir + f'/speciesBase64.json', 'w') as out_file:
    out_file.write(json_str)
