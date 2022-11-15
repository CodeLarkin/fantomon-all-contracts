/*
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IFantomonRegistry.sol";
import "./IFantomonStore.sol";
import "./IFantomonNaming.sol";
import "./IFantomonArt.sol";
import "./IFantomonGraphics.sol";

import {FantomonFunctions} from "./FantomonFunctions.sol";

/* Visualizations and string-based info for Fantomons */
contract FantomonGraphicsV1 is IFantomonGraphics, Ownable {
    using FantomonFunctions for FantomonLib.Fmon;

    bool private IMAGE_EMBED = false;

    uint48 constant public MAX_XP      = 1069420000000;  // XP at max level:       1069420 * 1E6
    uint48 constant public MAX_MASTERY =     300000000;  // Max combined stat mastery: 300 * 1E6

    uint48 constant private ONE_MIL = 1000000;

    IFantomonRegistry public registry_;

    // Art is stored on-chain - base64 encodings set in this contract
    IFantomonArt public art_;

    mapping(uint8 => uint8) morphedIdx_; // maps unmorphed species index (0-41) to corresponding morphed species index (0-4)

    string[42] public SPECIES = [
        // AQUA
        "Exotius",
        "Waroda",
        "Flamphy",
        "Buui",
        "Jilius",
        "Octmii",
        "Starfy",
        "Luupe",
        "Milius",
        "Shelfy",  // Ancient

        // CHAOS
        "Ephisto",
        "Kazaaba", // Ancient

        // COSMIC
        "Xatius",
        "Tapoc",
        "Slusa",
        "Cosmii",

        // DEMON
        "Decro",
        "Merich",
        "Zeepuu",

        // FAIRY
        "Huffly",
        "Munsa",
        "Fenii",
        "Fleppa",
        "Mii",
        "Jixpi",  // Ancient

        // GUNK
        "Kaibu",
        "Koob",
        "Woobek",
        "Googa",
        "Piniju",
        "Gubba",
        "Belkezor",

        // MINERAL
        "Meph",
        "Relixia",  // Ancient

        // PLANT
        "Shrooto",
        "Sphin",
        "Rooto",
        "Icaray",
        "Brutu",
        "Grongel",  // Ancient

        // Starter
        "Larik",  // Aqua
        "Gretto"  // Chaos
    ];


    string[8] public TYPES = [
        "Aqua",    // 10 species, 1 ancient
        "Chaos",   //  2 species, 1 ancient
        "Cosmic",  //  4 species
        "Demon",   //  3 species
        "Fairy",   //  6 species, 1 ancient
        "Gunk",    //  7 species
        "Mineral", //  2 species, 1 ancient
        "Plant"    //  6 species, 1 ancient
    ];

    string[2] public CLASSES = [
        "Relic",
        "Ancient"
    ];


    string[24] public ATTACKS = [
        // NORMAL ATTACKS

        // Common: 10% each
        "Spit"                ,
        "Meditate"            ,
        "Gunk Barrage"        ,

        // Rare: 5% each
        "Tomb Crush"          ,
        "Meta Splash"         ,
        "Regenerate"          ,

        // Epic: 1.33% each
        "Spook"               ,
        "Opera Shriek"        ,
        "Chain Block"         ,

        // Legendary: 0.33% each
        "Lachesis Blitz"      ,
        "Mush"                ,
        "Meteor Volley"       ,

        // SPECIAL ATTACKS

        // Common: 10% each
        "Eclipse Flash"       ,
        "Cosmic Reaper"       ,
        "Graviton Beam"       ,

        // Rare: 5% each
        "Soul Siphon"         ,
        "Galaxy Bomb"         ,
        "Forge Spirit"        ,
        // Epic: 1.33% each
        "Mimick Spell"        ,
        "Dark Matter Assault" ,
        "Fantom Flare"        ,
        // Legendary: 0.33% each
        "Resurrect"           ,
        "Moonshot"            ,
        "Chorus of Skulls"
    ];

    string[24] private ATTACK_POWERS = [
        // NORMAL ATTACKS

        // Common: 10% each
         '9', // Spit
        '14', // Meditate
        '12', // Gunk Barrage

        // Rare: 5% each
        '15',  // Tomb Crush
         '5',  // Meta Splash
         '*',  // Regenerate

        // Epic: 1.33% each
        '18',  // Spook
        '20',  // Opera Shriek
        '15',  // Chain Block

        // Legendary: 0.33% each
        '25',  // Lachesis Blitz
        '40',  // Mush
        '30',  // Meteor Volley

        // SPECIAL ATTACKS

        // Common: 10% each
        '25',  // Eclipse Flash
        '30',  // Cosmic Reaper
        '20',  // Graviton Beam

        // Rare: 5% each
        '25',  // Soul Siphon
        '45',  // Galaxy Bomb
        '30',  // Forge Spirit

        // Epic: 1.33% each
        '50',  // Mimick Spell
        '55',  // Dark Matter Assault
        '40',  // Fantom Flare

        // Legendary: 0.33% each
         '*',  // Resurrect
        '55',  // Moonshot
        '65'   // Chorus of Skulls
    ];


    string[5] public MOODS = [      // variance effects
        "Often Munchy",    // 35%   (least-significant digit 0-5)
        "Mischievous",     // 27.5% (least-significant digit 1-6)
        "Very Playful",    // 20%   (least-significant digit 2-7)
        "Battle Ready",    // 12.5% (least-significant digit 3-8)
        "Cosmic Veteran"   //  5%   (least-significant digit 4-9)
    ];


    string[14] public ESSENCES = [
        // 40% = 20% each
        "Shy"      ,  //  9000
        "Docile"   ,  //  9000
        // 49% =  7% each
        "Alert"    ,  // 10000
        "Swift"    ,  // 10000
        "Nimble"   ,  // 10000
        "Agile"    ,  // 10000
        "Wild"     ,  // 10000
        "Sneaky"   ,  // 10000
        "Reckless" ,  // 10000
        // 11% =  2.2% each
        "Spunky"   ,  // 11000
        "Spirited" ,  // 11000
        "Fiery"    ,  // 11000
        "Smart"    ,  // 11000
        "Cosmic"      // 11000
    ];

    // Labels for serialized Fmon (same entry-order as in FantomonLib)
    string[29] attributeLabels = [
        "level"                 ,
        "morph"                 ,
        "xp"                    ,
        "baseHp"                ,
        "baseAttack"            ,
        "baseDefense"           ,
        "baseSpAttack"          ,
        "baseSpDefense"         ,
        "hp"                    ,
        "attack"                ,
        "defense"               ,
        "spAttack"              ,
        "spDefense"             ,
        "hpNutrients"           ,
        "attackNutrients"       ,
        "defenseNutrients"      ,
        "spAttackNutrients"     ,
        "spDefenseNutrients"    ,
        "hpMastery"             ,
        "attackMastery"         ,
        "defenseMastery"        ,
        "spAttackMastery"       ,
        "spDefenseMastery"      ,
        "hpVariance"            ,
        "attackVariance"        ,
        "defenseVariance"       ,
        "defenseVariance"       ,
        "spAttackVariance"      ,
        "spDefenseVariance"
        // These require special treatment since they are indices
        //"species"               ,
        //"type"                  ,
        //"class"                 ,
        //"mood"                  ,
        //"essence"               ,
        //"attack0"               ,
        //"attack1"
    ];


    constructor(address _registry) {
        registry_ = IFantomonRegistry(_registry);

        morphedIdx_[ 9] = 42; // Shelfy is the 0th Ancient/morphable
        morphedIdx_[11] = 43; // Kazaaba ''
        morphedIdx_[24] = 44; // Jixpi   ''
        morphedIdx_[33] = 45; // Relixia ''
        morphedIdx_[39] = 46; // Grongel ''
    }

    function setRegistry(address _registry) external onlyOwner {
        registry_ = IFantomonRegistry(_registry);
    }

    function setArt(IFantomonArt _art) external onlyOwner {
        art_ = _art;
    }

    function getName(uint256 _tokenId) public view returns (string memory) {
        IFantomonStore fstore = registry_.fstore_();
        IFantomonNaming naming = IFantomonNaming(registry_.others_('naming'));
        FantomonLib.Attributes memory attrs = fstore.fmon(_tokenId).attrs;
        if (bytes(naming.names_(_tokenId)).length == 0) {
            return string(abi.encodePacked("Unknown ", SPECIES[attrs.species]));
        } else {
            return naming.names_(_tokenId);
        }
    }

    function getXpOfNextLvl(uint8 _lvl) private pure returns (string memory) {
        return _lvl == 100 ? toString(MAX_XP / ONE_MIL) :  toString(FantomonLib.lvl2Xp(_lvl) / ONE_MIL);
    }
    function xpPixels(uint8 _lvl, uint256 _xp, uint256 _maxPixels) private pure returns (string memory) {
        if (_lvl == 100) {
            return toString(_maxPixels);
        }
        uint256 xpOfCurrLvl = FantomonLib.lvl2Xp(_lvl - 1);
        uint256 xpOfNextLvl = FantomonLib.lvl2Xp(_lvl);
        uint256 totalXpToLevel = xpOfNextLvl - xpOfCurrLvl;
        uint256 currXpToLevel  = _xp - xpOfCurrLvl;
        return toString((_maxPixels * currXpToLevel) / totalXpToLevel);
    }

    function hpPixels(uint256 _hp, uint256 _dmg, uint256 _maxPixels) public pure returns (string memory) {
        return toString((_maxPixels * (_hp - _dmg)) / _hp);
    }

    // Visualizations
    function pngURI(uint256 _tokenId) public view returns (string memory) {
        FantomonLib.Fmon memory fmon = registry_.fstore_().fmon(_tokenId);
        FantomonLib.Attributes memory attrs = fmon.attrs;
        // Art is split into contracts each containing 5 species PNGs
        if (fmon.morph > 0) {
            return art_.PNGS(morphedIdx_[attrs.species]);
        } else {
            return art_.PNGS(attrs.species);
        }
    }

    function imageURI(uint256 _tokenId) public view returns (string memory) {
        string[81] memory parts;
        FantomonLib.Fmon memory fmon = registry_.fstore_().fmon(_tokenId);
        FantomonLib.Attributes memory attrs = fmon.attrs;
        FantomonLib.Stats memory stats = fmon.scale();

        uint8 x = 0;
        parts[x] = '<svg style="width: 100%; height: 100%" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 124 225">'
                       '<style> .base { fill: white; font-family: Courier; font-size: 7px; }</style>'
                       '<style> .mid  { fill: white; font-family: Courier; font-size: 6px; }</style>'
                       '<style> .mini { fill: white; font-family: Courier; font-size: 5px; }</style>'
                       '<style> .gen  { fill: gold;  font-family: Courier; font-size: 6px; }</style>'; x++;

        // Name
        parts[x] = '<image style="width: 100%; height: 100%" xlink:href="'; x++;
        parts[x] = pngURI(_tokenId); x++;
        parts[x] = '" alt="Fantomon Art"></image>'; x++;
        parts[x] = '<text x="50%" y="5.1%" text-anchor="middle" font-weight="bold" class="base">'; x++;
        parts[x] = getName(_tokenId); x++ ;
        // Level
        parts[x] = '</text>'
                   '<text x="95%" y="5.1%" text-anchor="end" font-weight="bold" class="base"><tspan style="font-size: 3px">LV </tspan>'; x++;
        parts[x] = toString(fmon.lvl); x++;

        // HP bar
        parts[x] = '</text>'
                   '<text x="5.8%" y="53.4%" class="mid">HP</text>'
                   '<text x="95%" y="53.4%" text-anchor="end" class="mid">'; x++;
        // check if remaining HP is between 0 and 1 to add <1 if so.
        if (stats.hp > fmon.dmg && (stats.hp - fmon.dmg) < ONE_MIL) {
            parts[x] = '&#xfe64;1'; x++;
        } else {
            parts[x] = toString((stats.hp - fmon.dmg) / ONE_MIL); x++;
        }
        parts[x] = '/'; x++;
        parts[x] = toString(stats.hp / ONE_MIL); x++;
        parts[x] = '</text>'
                   '<rect x="6%" y="54.3%" width="88.4%" height="0.7%" style="fill:red;stroke:#120f16;stroke-width:0.3%;fill-opacity:1"/>'
                   '<rect x="6.2%" y="54.4%" width="'; x++;
        parts[x] = hpPixels(stats.hp, fmon.dmg, 88); x++;
        parts[x] = '%" height="0.46%" style="fill:lime;fill-opacity:1" />'
                   '<text x="5.8%" y="58.2%" class="mid">Attack:</text>'
                   '<text x="43%" y="58.2%" text-anchor="end" class="mid">'; x++;
        parts[x] = toString(stats.attack / ONE_MIL); x++;
        parts[x] = '</text>'
                   '<text x="5.8%" y="61.2%" class="mid">Defense:</text>'
                   '<text x="43%" y="61.2%" text-anchor="end" class="mid">'; x++;
        parts[x] = toString(stats.defense / ONE_MIL); x++;
        parts[x] = '</text>'
                   '<text x="50%" y="58.2%" class="mid">Sp Attack:</text>'
                   '<text x="95%" y="58.2%" text-anchor="end" class="mid">'; x++;
        parts[x] = toString(stats.spAttack / ONE_MIL); x++;
        parts[x] = '</text>'
                   '<text x="50%" y="61.2%" class="mid">Sp Defense:</text>'
                   '<text x="95%" y="61.2%" text-anchor="end" class="mid">'; x++;
        parts[x] = toString(stats.spDefense / ONE_MIL); x++;
        parts[x] = '</text>'
                   '<text x="5.8%" y="64.8%" text-decoration="underline" class="mid">Attacks:</text>'; x++;
        if (fmon.attacks.attack0 >= 12) {
            parts[x] = '<circle cx="8%" cy="67%" r="0.7%" fill="gold"/>'; x++;
            parts[x] = '<text x="11%" y="67.9%" class="mid">'; x++;
        } else {
            parts[x] = '<text x="5.8%" y="67.9%" class="mid">'; x++;
        }
        parts[x] = ATTACKS[fmon.attacks.attack0]; x++;
        parts[x] = '</text>'; x++;
        if (fmon.attacks.attack1 >= 12) {
            parts[x] = '<circle cx="8%" cy="69.8%" r="0.7%" fill="gold"/>'; x++;
            parts[x] = '<text x="11%" y="70.7%" class="mid">'; x++;
        } else {
            parts[x] = '<text x="5.8%" y="70.7%" class="mid">'; x++;
        }
        parts[x] = ATTACKS[fmon.attacks.attack1]; x++;
        parts[x] = '</text>'; x++;

        parts[x] = '<text x="95%" y="64.8%" text-anchor="end" text-decoration="underline" class="mid">Power</text>'
                   '<text x="95%" y="67.9%" text-anchor="end" class="mid">'; x++;
        parts[x] = ATTACK_POWERS[fmon.attacks.attack0]; x++;
        parts[x] = '</text>'
                   '<text x="95%" y="70.7%" text-anchor="end" class="mid">'; x++;
        parts[x] = ATTACK_POWERS[fmon.attacks.attack1]; x++;

        // XP bar
        parts[x] = '</text>'
                   '<text x="5.8%" y="74.3%" class="mid">XP</text>'
                   '<text x="95%" y="74.3%" text-anchor="end" class="mid">'; x++;
        parts[x] = toString(fmon.xp / ONE_MIL); x++;
        parts[x] = '/'; x++;
        parts[x] = getXpOfNextLvl(fmon.lvl); x++;
        parts[x] = '</text>'
                   '<rect x="6%" y="75.3%" width="88.4%" height="0.7%" style="fill:white;stroke:#120f16;stroke-width:0.3%;fill-opacity:1" />'
                   '<rect x="6.2%" y="75.4%" width="'; x++;
        parts[x] = xpPixels(fmon.lvl, fmon.xp, 88); x++;
        parts[x] = '%" height="0.5%" style="fill:blue;fill-opacity:1"/>'; x++;

        parts[x] = '<text x="5.8%" y="81.1%" class="mini">Species: '; x++;
        if (fmon.morph > 0) {
            parts[x] = 'Morphed '; x++;
        }
        parts[x] = SPECIES[attrs.species]; x++;
        parts[x] = '</text>'
                   '<text x="5.8%" y="83.6%"   class="mini">Type:&#160;&#160;&#160; '; x++;
        parts[x] = TYPES[attrs.typ]; x++;
        parts[x] = '</text>'
                   '<text x="5.8%" y="86.1%" class="mini">Class:&#160;&#160; '; x++;
        parts[x] = CLASSES[attrs.class]; x++;
        parts[x] = '</text>'
                   '<text x="5.8%" y="88.6%" class="mini">Mood:&#160;&#160;&#160; '; x++;
        parts[x] = MOODS[attrs.mood]; x++;
        parts[x] = '</text>'
                   '<text x="5.8%" y="91.1%" class="mini">Essence: '; x++;
        parts[x] = ESSENCES[attrs.essence]; x++;
        parts[x] = '</text>'
                   '<text x="5.8%" y="97%"  class="gen">'; x++;
        if (attrs.species < 40) { // 40 and 41 are Starters
            parts[x] = 'Generation 1'; x++ ;
        } else {
            parts[x] = 'Starter'; x++ ;
        }
        parts[x] = '</text>'
                   '<text x="95%" y="97%" text-anchor="end" class="mid">#'; x++;
        parts[x] = toString(_tokenId); x++;
        parts[x] = '</text>'
                   '</svg>'; x++;



        uint8 i;
        string memory output = string(abi.encodePacked(parts[0], parts[1],  parts[2],  parts[3],  parts[4],  parts[5],  parts[6],  parts[7],  parts[8]));
        for (i = 9; i < 81; i += 8) {
            output = string(abi.encodePacked(output, parts[i], parts[i+1], parts[i+2], parts[i+3], parts[i+4], parts[i+5], parts[i+6], parts[i+7]));
        }
        return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(output))));
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        string[90] memory parts;

        FantomonLib.Fmon memory fmon = registry_.fstore_().fmon(_tokenId);
        FantomonLib.Attributes memory attrs = fmon.attrs;

        uint8 x = 0;
        parts[x] = '{"name":"'                                         ; x++ ;
        parts[x] = getName(_tokenId)                                   ; x++ ;
        parts[x] = '", "tokenId":"'                                    ; x++ ;
        parts[x] = toString(_tokenId)                                  ; x++ ;
        parts[x] = '", "attributes":[{"trait_type":"name","value":"'   ; x++ ;
        parts[x] = getName(_tokenId)                                   ; x++ ;
        uint256[36] memory allAttrs = fmon.serialize();
        for (uint8 a; a < 29; a++) {
            parts[x] = string(abi.encodePacked('"}, {"trait_type":"', attributeLabels[a], '", "value":"', toString(allAttrs[a])));
            x++;
        }
        parts[x] = '"}, {"trait_type":"species", "value":"'            ; x++ ;
        parts[x] = SPECIES[attrs.species]                              ; x++ ;
        parts[x] = '"}, {"trait_type":"type", "value":"'               ; x++ ;
        parts[x] = TYPES[attrs.typ]                                    ; x++ ;
        parts[x] = '"}, {"trait_type":"class", "value":"'              ; x++ ;
        parts[x] = CLASSES[attrs.class]                                ; x++ ;
        parts[x] = '"}, {"trait_type":"mood", "value":"'               ; x++ ;
        parts[x] = MOODS[attrs.mood]                                   ; x++ ;
        parts[x] = '"}, {"trait_type":"essence", "value":"'            ; x++ ;
        parts[x] = ESSENCES[attrs.essence]                             ; x++ ;
        parts[x] = '"}, {"trait_type":"attack0", "value":"'            ; x++ ;
        parts[x] = ATTACKS[fmon.attacks.attack0]                       ; x++ ;
        parts[x] = '"}, {"trait_type":"attack1", "value":"'            ; x++ ;
        parts[x] = ATTACKS[fmon.attacks.attack1]                       ; x++ ;
        if (attrs.species < 40) { // 40 and 41 are Starters
            parts[x] = '"}, {"trait_type":"generation", "value":"1"}], '       ; x++ ;
        } else {
            parts[x] = '"}, {"trait_type":"generation", "value":"Starter"}], ' ; x++ ;
        }
        parts[x] = '"image":"'                                       ; x++ ;
        parts[x] = imageURI(_tokenId)                                ; x++ ;
        parts[x] = '", '                                             ; x++ ;

        string memory json = string(abi.encodePacked(parts[0], parts[1],  parts[2],  parts[3],  parts[4],  parts[5],  parts[6],  parts[7],  parts[8]));
        uint8 i;
        for (i = 9; i < 89; i += 8) {
            json = string(abi.encodePacked(json, parts[i], parts[i+1], parts[i+2], parts[i+3], parts[i+4], parts[i+5], parts[i+6], parts[i+7]));
        }

        json = Base64.encode(bytes(string(abi.encodePacked(json, '"description": "Fantomons are feedable and battle-ready entities for the Fantomons Play-to-Earn game. Attributes (species, type, class, mood, essence and attacks) are randomly chosen (and impacted by your selected Trainer profile) and stored on-chain. Variances are derived from mood and class, and are used as stat modifiers along with essence. Base-stats are based on species, but they scale with nutrients (feeding), mastery (fighting), and leveling. Fantomon Trainers can pet, play and sing to Fantomons. Start playing at Fantomon.net!"}'))));
        json = string(abi.encodePacked('data:application/json;base64,', json));

        return json;
    }


    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
