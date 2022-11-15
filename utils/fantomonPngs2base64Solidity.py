import sys
import math
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


BATCH_SIZE = 4
NUM_BATCHES = math.ceil(float(len(SPECIES))/BATCH_SIZE)

for batch in range(0, NUM_BATCHES):
    min = batch*BATCH_SIZE
    max = (batch+1)*BATCH_SIZE
    if max > len(SPECIES):
        max = len(SPECIES)

    contract = f'FantomonArt{min}to{max-1}'

    sol_txt = '''
/*
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
*/

'''
    sol_txt += '// SPDX-License-Identifier: MIT\n\n'
    sol_txt += 'pragma solidity ^0.8.9;\n'
    sol_txt += 'import "./IFantomonArt.sol";\n\n'
    sol_txt += f'contract {contract} ' + 'is IFantomonArt {\n'
    sol_txt += f'    string[{max-min}] public PNGS = ['

    for idx, species in enumerate(SPECIES[min:max]):
        png = image_dir + '/' + species + 'Card.png'
        with open(png, 'rb') as png_file:
            encoded_png = base64.b64encode(png_file.read()).decode('ascii')
        sol_txt += '\n        // ' + species
        sol_txt += '\n        "data:image/png;base64,' + encoded_png + '"'
        if idx != max-min-1:
            sol_txt += ','
    sol_txt += '\n    ];'
    sol_txt += '\n}'

    with open(out_dir + f'/{contract}.sol', 'w') as out_file:
        out_file.write(sol_txt)

BATCH_SIZE = 3
NUM_BATCHES = math.ceil(float(len(MORPHS))/BATCH_SIZE)

for batch in range(0, NUM_BATCHES):
    min = batch*BATCH_SIZE
    max = (batch+1)*BATCH_SIZE
    if max > len(MORPHS):
        max = len(MORPHS)

    contract = f'FantomonMorphedArt{min}to{max-1}'

    sol_txt = '''
/*
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
*/

'''
    sol_txt += '// SPDX-License-Identifier: MIT\n\n'
    sol_txt += 'pragma solidity ^0.8.9;\n'
    sol_txt += 'import "./IFantomonArt.sol";\n\n'
    sol_txt += f'contract {contract} ' + 'is IFantomonArt {\n'
    sol_txt += f'    string[{max-min}] public PNGS = ['

    for idx, species in enumerate(MORPHS[min:max]):
        png = image_dir + '/' + species + 'Card.png'
        with open(png, 'rb') as png_file:
            encoded_png = base64.b64encode(png_file.read()).decode('ascii')
        sol_txt += '\n        // ' + species
        sol_txt += '\n        "data:image/png;base64,' + encoded_png + '"'
        if idx != max-min-1:
            sol_txt += ','
    sol_txt += '\n    ];'
    sol_txt += '\n}'

    with open(out_dir + f'/{contract}.sol', 'w') as out_file:
        out_file.write(sol_txt)
