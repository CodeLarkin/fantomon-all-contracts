/*
by
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
with help from
░██╗░░░░░░░██╗░█████╗░████████╗███████╗██████╗░██╗░░██╗██████╗░░█████╗░██████╗░
░██║░░██╗░░██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██║░░██║╚════██╗██╔══██╗╚════██╗
░╚██╗████╗██╔╝███████║░░░██║░░░█████╗░░██████╔╝███████║░░███╔═╝██║░░██║░█████╔╝
░░████╔═████║░██╔══██║░░░██║░░░██╔══╝░░██╔══██╗██╔══██║██╔══╝░░██║░░██║░╚═══██╗
░░╚██╔╝░╚██╔╝░██║░░██║░░░██║░░░███████╗██║░░██║██║░░██║███████╗╚█████╔╝██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░╚════╝░╚═════╝░
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IFantomonTrainer.sol";
import "./IFantomonArt.sol";

contract FantomonTrainerGraphicsV3 is Ownable {

    IFantomonTrainer trainers_;
    IFantomonArt art_;

    constructor (IFantomonTrainer _trainers) {
        trainers_ = _trainers;
    }

    function initArt(address _art) external onlyOwner {
        art_ = IFantomonArt(_art);
    }

    string[5] private STATUSES = ["WATCHING ANIME", "PREPARING FOR BATTLE", "BATTLING", "TREATING WOUNDS", "LOST"];

    uint8 constant private RESTING   = 0;
    uint8 constant private PREPARING = 1;
    uint8 constant private BATTLING  = 2;
    uint8 constant private HEALING   = 3;
    uint8 constant private LOST      = 4;

    string[4] private RARITIES = ["Common", "Rare", "Epic", "Legendary"];

    string[16] private CLASSES = [
        // 60%
        "Botanist",
        "Zoologist",
        "Hydrologist",
        "Entomologist",

        // 30%
        "Biochemist",
        "Microbiologist",
        "Biotechnologist",
        "Biomedical Engineer",

        // 9%
        "Geneticist",
        "Astrophysicist",
        "String Theorist",
        "Quantum Physicist",

        // 1%
        "Ent Mystic",
        "Ent Theorist",
        "Cosmic Explorer",
        "Ancient Ent Master"
    ];

    string[7] private FACES = ["1", "2", "3", "4", "5", "6", "7"];

    string[13] private WORLDS = [
        // 60%
        "Gunka",
        "Sha'afta",
        "Jiego ",
        "Beck S68",
        "Gem Z32",

        // 30%
        "Junapla",
        "Strigah",
        "Mastazu",

        // 9%
        "Clyve R24",
        "Larukin",
        "H-203",

        // 1%
        "Ancient Territories",
        "Relics Rock"
    ];

    // Getters
    function getTrainerName(uint256 _tokenId) public view returns (string memory) {
        return trainers_.getTrainerName(_tokenId);
    }
    function getKinship(uint256 _tokenId) public view returns (string memory) {
        return toString(trainers_.getKinship(_tokenId));
    }
    function getFlare(uint256 _tokenId) public view returns (string memory) {
        return toString(trainers_.getFlare(_tokenId));
    }
    function getHealing(uint256 _tokenId) public view returns (string memory) {
        return toString(trainers_.getHealing(_tokenId));
    }
    function getCourage(uint256 _tokenId) public view returns (string memory) {
        return toString(trainers_.getCourage(_tokenId));
    }
    function getWins(uint256 _tokenId) public view returns (string memory) {
        return toString(trainers_.getWins(_tokenId));
    }
    function getLosses(uint256 _tokenId) public view returns (string memory) {
        return toString(trainers_.getLosses(_tokenId));
    }
    function getClass(uint256 _tokenId) public view returns (string memory) {
        return CLASSES[trainers_.getClass(_tokenId)];
    }
    function getFace(uint256 _tokenId) public view returns (string memory) {
        return FACES[trainers_.getFace(_tokenId)];
    }
    function getHomeworld(uint256 _tokenId) public view returns (string memory) {
        return WORLDS[trainers_.getHomeworld(_tokenId)];
    }
    function getRarity(uint256 _tokenId) public view returns (string memory) {
        return RARITIES[trainers_.getRarity(_tokenId)];
    }
    function getStatus(uint256 _tokenId) public view returns (string memory) {
        return STATUSES[trainers_.getStatus(_tokenId)];
    }

    function imageURI(uint256 _tokenId) public view returns (string memory) {
        string[41] memory parts;
        uint8 x = 0;
        parts[x]  = '<svg width="100%" height="100%" viewBox="0 0 246 448" xmlns="http://www.w3.org/2000/svg"  xmlns:xlink="http://www.w3.org/1999/xlink">'
                    '<style>.base { fill: black; font-family: Courier; font-size: 16px; }'
                    '</style>'
                    '<style>.trailer { fill: white; font-family: Courier; font-size: 12.2px; }'
                    '</style>'
                    '<style>.trailerGen { fill: gold; font-family: Courier; font-size: 12.2px; }'
                    '</style>'; x++;
        parts[x]  = '<image width="100%" height="100%" xlink:href="'; x++;
        parts[x]  = art_.PNGS((trainers_.getRarity(_tokenId) * 7) + trainers_.getFace(_tokenId)); x++;
        parts[x]  = '"/><text x="50%" y="5.5%" text-anchor="middle" font-weight="bold" class="base">'; x++;
        parts[x]  =     getTrainerName(_tokenId); x++;
        parts[x]  = '</text>'
                    '<text x="6%" y="54.24%" font-weight="bold" class="base">'
                        'Kinship: '; x++;
        parts[x]  =     getKinship(_tokenId); x++;
        parts[x]  = '</text>'
                    '<text x="6%" y="58.48%" font-weight="bold" class="base">'
                        'Flare: '; x++;
        parts[x]  =    getFlare(_tokenId); x++;
        parts[x]  = '</text>'
                    '<text x="6%" y="62.72%" font-weight="bold" class="base">'
                        'Healing: '; x++;
        parts[x] =     getHealing(_tokenId); x++;
        parts[x] = '</text>'
                    '<text x="6%" y="66.96%" font-weight="bold" class="base">'
                        'Courage: '; x++;
        parts[x]  =    getCourage(_tokenId); x++;
        parts[x] = '</text>'
                    '<text x="6%" y="71.20%" class="base">'
                        'Wins: '; x++;
        parts[x] =     getWins(_tokenId); x++;
        parts[x] = '</text>'
                    '<text x="6%" y="75.44%" class="base">'
                        'Losses: '; x++;
        parts[x] =     getLosses(_tokenId); x++;
        parts[x] = '</text>'
                    '<text x="6%" y="81.47%" class="trailer">'
                        'Class: '; x++;
        parts[x] =     getClass(_tokenId); x++;
        parts[x] = '</text>'
                    '<text x="6%" y="84.82%" class="trailer">'
                        'Homeworld: '; x++;
        parts[x] =     getHomeworld(_tokenId); x++;
        parts[x] = '</text>'
                    '<text x="6%" y="88.16%" class="trailer">'
                        'Rarity: '; x++;
        parts[x] =     getRarity(_tokenId); x++;
        parts[x] = '</text>'
                    '<text x="6%" y="92.85%" class="trailer">'
                        'Status: '; x++;
        parts[x] =     getStatus(_tokenId); x++;
        if (trainers_.getStatus(_tokenId) == RESTING) {  // if RESTING, green box
            parts[x] = '</text><rect x="4%" y="89.95%" width="92%" height="3.79%" style="fill:lime;stroke:lime;stroke-width:2;fill-opacity:0.1;stroke-opacity:0.9" />';
        } else if (trainers_.getStatus(_tokenId) == PREPARING) {  // if PREPARING, yellow box
            parts[x] = '</text><rect x="4%" y="89.95%" width="92%" height="3.79%" style="fill:yellow;stroke:yellow;stroke-width:2;fill-opacity:0.1;stroke-opacity:0.9" />';
        } else if (trainers_.getStatus(_tokenId) == BATTLING) {  // if BATTLING, blue box
            parts[x] = '</text><rect x="4%" y="89.95%" width="92%" height="3.79%" style="fill:cyan;stroke:cyan;stroke-width:2;fill-opacity:0.1;stroke-opacity:0.9" />';
        } else if (trainers_.getStatus(_tokenId) == HEALING) {  // if HEALING, red box
            parts[x] = '</text><rect x="4%" y="89.95%" width="92%" height="3.79%" style="fill:red;stroke:red;stroke-width:2;fill-opacity:0.1;stroke-opacity:0.9" />';
        } else {  // if (trainers_.getStatus(_tokenId) == LOST) {  // if LOST, magenta box
            parts[x] = '</text><rect x="4%" y="89.95%" width="92%" height="3.79%" style="fill:magenta;stroke:magenta;stroke-width:2;fill-opacity:0.1;stroke-opacity:0.9" />';
        }
        x++;
        parts[x] = '<text x="6%" y="97.09%" font-weight="bold" class="trailerGen">'
                        'Generation 1'
                    '</text>'
                    '<text x="94%" y="97.09%" text-anchor="end" class="trailer">#'; x++;
        parts[x] =     toString(_tokenId); x++;
        parts[x] = '</text>'; x++;
        parts[x] = '</svg>'; x++;

        uint8 i;
        string memory output = string(abi.encodePacked(parts[0], parts[1],  parts[2],  parts[3],  parts[4],  parts[5],  parts[6],  parts[7],  parts[8]));
        for (i = 9; i < 41; i += 8) {
            output = string(abi.encodePacked(output, parts[i], parts[i+1], parts[i+2], parts[i+3], parts[i+4], parts[i+5], parts[i+6], parts[i+7]));
        }
        return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(output))));
    }

    // Visualizations
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        string[41] memory parts;
        uint8 x = 0;
        parts[x] = '{"name":"'                                       ; x++ ;
        parts[x] = getTrainerName(_tokenId)                          ; x++ ;
        parts[x] = '", "trainerId":"'                                ; x++ ;
        parts[x] = toString(_tokenId)                                ; x++ ;
        parts[x] = '", "image":"'                                    ; x++ ;
        parts[x] = imageURI(_tokenId)                                ; x++ ;
        parts[x] = '", "attributes":[{"trait_type":"name","value":"' ; x++ ;
        parts[x] = getTrainerName(_tokenId)                          ; x++ ;
        parts[x] = '"}, {"trait_type":"avatar", "value":"'           ; x++ ;
        parts[x] = getFace(_tokenId)                                 ; x++ ;
        parts[x] = '"}, {"trait_type":"kinship", "value":"'          ; x++ ;
        parts[x] = getKinship(_tokenId)                              ; x++ ;
        parts[x] = '"}, {"trait_type":"flare", "value":"'            ; x++ ;
        parts[x] = getFlare(_tokenId)                                ; x++ ;
        parts[x] = '"}, {"trait_type":"healing", "value":"'          ; x++ ;
        parts[x] = getHealing(_tokenId)                              ; x++ ;
        parts[x] = '"}, {"trait_type":"courage", "value":"'          ; x++ ;
        parts[x] = getCourage(_tokenId)                              ; x++ ;
        parts[x] = '"}, {"trait_type":"wins", "value":"'             ; x++ ;
        parts[x] = getWins(_tokenId)                                 ; x++ ;
        parts[x] = '"}, {"trait_type":"losses", "value":"'           ; x++ ;
        parts[x] = getLosses(_tokenId)                               ; x++ ;
        parts[x] = '"}, {"trait_type":"class", "value":"'            ; x++ ;
        parts[x] = getClass(_tokenId)                                ; x++ ;
        parts[x] = '"}, {"trait_type":"homeworld", "value":"'        ; x++ ;
        parts[x] = getHomeworld(_tokenId)                            ; x++ ;
        parts[x] = '"}, {"trait_type":"rarity", "value":"'           ; x++ ;
        parts[x] = getRarity(_tokenId)                               ; x++ ;
        parts[x] = '"}, {"trait_type":"status", "value":"'           ; x++ ;
        parts[x] = getStatus(_tokenId)                               ; x++ ;
        parts[x] = '"}, {"trait_type":"generation", "value":"1"}], ' ; x++ ;

        string memory json = string(abi.encodePacked(parts[0], parts[1],  parts[2],  parts[3],  parts[4],  parts[5],  parts[6],  parts[7],  parts[8]));
        uint8 i;
        for (i = 9; i < 41; i += 8) {
            json = string(abi.encodePacked(json, parts[i], parts[i+1], parts[i+2], parts[i+3], parts[i+4], parts[i+5], parts[i+6], parts[i+7]));
        }

        json = Base64.encode(bytes(string(abi.encodePacked(json, '"description": "Fantomon Trainers are player profiles for the Fantomons Play-to-Earn game. Attributes (class, homeworld, rarity, and avatar#) are randomly chosen and stored on-chain. Stats are initialized to 1, wins and losses to 0, and can be increased via interactions in the Fantomon universe. Start playing at Fantomon.net"}'))));
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
/*
by
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
with help from
░██╗░░░░░░░██╗░█████╗░████████╗███████╗██████╗░██╗░░██╗██████╗░░█████╗░██████╗░
░██║░░██╗░░██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██║░░██║╚════██╗██╔══██╗╚════██╗
░╚██╗████╗██╔╝███████║░░░██║░░░█████╗░░██████╔╝███████║░░███╔═╝██║░░██║░█████╔╝
░░████╔═████║░██╔══██║░░░██║░░░██╔══╝░░██╔══██╗██╔══██║██╔══╝░░██║░░██║░╚═══██╗
░░╚██╔╝░╚██╔╝░██║░░██║░░░██║░░░███████╗██║░░██║██║░░██║███████╗╚█████╔╝██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░╚════╝░╚═════╝░
*/
