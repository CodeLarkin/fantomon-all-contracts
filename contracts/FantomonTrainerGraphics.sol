/*
░██╗░░░░░░░██╗░█████╗░████████╗███████╗██████╗░██╗░░██╗██████╗░░█████╗░██████╗░
░██║░░██╗░░██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██║░░██║╚════██╗██╔══██╗╚════██╗
░╚██╗████╗██╔╝███████║░░░██║░░░█████╗░░██████╔╝███████║░░███╔═╝██║░░██║░█████╔╝
░░████╔═████║░██╔══██║░░░██║░░░██╔══╝░░██╔══██╗██╔══██║██╔══╝░░██║░░██║░╚═══██╗
░░╚██╔╝░╚██╔╝░██║░░██║░░░██║░░░███████╗██║░░██║██║░░██║███████╗╚█████╔╝██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░╚════╝░╚═════╝░

░█████╗░███╗░░██╗██████╗░  ██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██╔══██╗████╗░██║██╔══██╗  ██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
███████║██╔██╗██║██║░░██║  ██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██╔══██║██║╚████║██║░░██║  ██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
██║░░██║██║░╚███║██████╔╝  ███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░  ╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IFantomonTrainer.sol";

contract FantomonTrainerGraphics is Ownable {

    bool private IMAGE_EMBED = false;

    //string private _baseURIextended = "ipfs://bafybeib3qdfhsed43gsoj3l6lckwvbqgb7svficyyyxp53lxzn6lcouwmu/"
    string private _baseURIextended = "http://ipfs.io/ipfs/bafybeib3qdfhsed43gsoj3l6lckwvbqgb7svficyyyxp53lxzn6lcouwmu/";

    string[5] private STATUSES = ["WATCHING ANIME", "PREPARING FOR BATTLE", "BATTLING", "TREATING WOUNDS", "LOST"];

    uint8 constant private RESTING   = 0;
    uint8 constant private PREPARING = 1;
    uint8 constant private BATTLING  = 2;
    uint8 constant private HEALING   = 3;
    uint8 constant private LOST      = 4;

    string[4] private RARITIES = ["Common", "Rare", "Epic", "Legendary"];

    string constant private COMMON_CARD    = '#708155"/><stop offset="95%" stop-color="#daddc3"/></linearGradient></defs><rect x="2" y="2" width="242" height="444" style="fill:#daddc3;';
    string constant private RARE_CARD      = '#daddc3"/><stop offset="95%" stop-color="#a17a71"/></linearGradient></defs><rect x="2" y="2" width="242" height="444" style="fill:#a17a71;';
    string constant private EPIC_CARD      = '#ffdda2"/><stop offset="95%" stop-color="#c1e6e6"/></linearGradient></defs><rect x="2" y="2" width="242" height="444" style="fill:#c1e6e6;';
    string constant private LEGENDARY_CARD = '#181211"/><stop offset="95%" stop-color="#ffba6a"/></linearGradient></defs><rect x="2" y="2" width="242" height="444" style="fill:#ffba6a;';

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

    // Setters
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }
    function toggleEmbed() external onlyOwner {
        IMAGE_EMBED = !IMAGE_EMBED;
    }

    // Getters
    function getTrainerName(uint256 _tokenId, IFantomonTrainer _trainers) public view returns (string memory) {
        return _trainers.getTrainerName(_tokenId);
    }
    function getKinship(uint256 _tokenId, IFantomonTrainer _trainers) public view returns (string memory) {
        return toString(_trainers.getKinship(_tokenId));
    }
    function getFlare(uint256 _tokenId, IFantomonTrainer _trainers) public view returns (string memory) {
        return toString(_trainers.getFlare(_tokenId));
    }
    function getHealing(uint256 _tokenId, IFantomonTrainer _trainers) public view returns (string memory) {
        return toString(_trainers.getHealing(_tokenId));
    }
    function getCourage(uint256 _tokenId, IFantomonTrainer _trainers) public view returns (string memory) {
        return toString(_trainers.getCourage(_tokenId));
    }
    function getWins(uint256 _tokenId, IFantomonTrainer _trainers) public view returns (string memory) {
        return toString(_trainers.getWins(_tokenId));
    }
    function getLosses(uint256 _tokenId, IFantomonTrainer _trainers) public view returns (string memory) {
        return toString(_trainers.getLosses(_tokenId));
    }
    function getClass(uint256 _tokenId, IFantomonTrainer _trainers) public view returns (string memory) {
        return CLASSES[_trainers.getClass(_tokenId)];
    }
    function getFace(uint256 _tokenId, IFantomonTrainer _trainers) public view returns (string memory) {
        return FACES[_trainers.getFace(_tokenId)];
    }
    function getHomeworld(uint256 _tokenId, IFantomonTrainer _trainers) public view returns (string memory) {
        return WORLDS[_trainers.getHomeworld(_tokenId)];
    }
    function getRarity(uint256 _tokenId, IFantomonTrainer _trainers) public view returns (string memory) {
        return RARITIES[_trainers.getRarity(_tokenId)];
    }
    function getStatus(uint256 _tokenId, IFantomonTrainer _trainers) public view returns (string memory) {
        return STATUSES[_trainers.getStatus(_tokenId)];
    }
    function getImageURI(uint256 _tokenId, IFantomonTrainer _trainers) public view returns (string memory) {
        return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAHwAAADhCAMAAAA9OCERAAAAAXNSR0IArs4c6QAAAGxQTFRFAAAAIiA0RSg8Zjkxj1Y733Em2aBm7sOa+/I2meVQar4wN5RuS2kvUkskMjw5Pz90MGCCW27hY5v/X83ky9v8////m623hH6HaWpqWVZSdkKKrDIy2Vdj13u6j5dKim8wAAAD20BAnCYxdRQdQdTeYgAAACR0Uk5TAP//////////////////////////////////////////////9aRedAAAB75JREFUeJztnOnKo0oQhseTD+ZHRBGHgKDY4P3f46mtu6s3Y1YHpouZLCbx6be6Nj3M+WVOtF9mO81OhwP+6ysgJik/Rbxxbv9+rBGV4Gb+upkKr/B/EH5mnp9Z4c6t7WeZhRvTOIPXBh8/Z4SJ4GoBzWfpiHOpZhq3oC/RPbwxGfaH8HziJoF/EG/PxCEV7HmwKr35L/HKBwPlETtwQfZsh1bVlF7nlFtm6v1jsGNG2K2g3GQW8C4uP0ZFpsmm2keCnoVruP+AUW+Fhz8vw414PMa/F95k4abg+YPRfRSeV17ivy3YG8uGx6TIZNHN23ocu5wyjR5T5UmaG7XrL7m/kQzfcXuuxlj+a+XW2UN7jpv+suOJyn/2lGfLq7j+Vb8rdFZ5Dv4WOwaPFkBv38VPB8jkK29p6Dk2J5usoajcmBL7hQVFAR/28wDRvLePM5xbudDLe/6J0V0Uc31LuppK6ISdXcwjC2wcvMn280Mne9YjTcAOGosu4rKKPOVJdpTkurHIGPXceY/DjW8V+WHik2yfbbup9gG4fWEKqaZ0v9UFsUNTtzfqkmoXvoC574UHSnD9ZgJr0mu1cHGlCrvgLY1FnXTBuxz7dI8VK8P3u+kAOKNgwF7o6F1sp2wqK9/ragPVQQWn9wW4RSk4Ky/DbU7mTkfUxvSWvvTs/bzfp6w1ebf7mxQF+CKP/bCwDb07ltOslQMSHuZmnufdgCt6vTf09V7BezywmT5UeyUTKt/zZDqh70S7jffch1sP8JHYI8D78AxXZcEN1xWh62xrHMO7Lot3180RGawfhpGlw/PQb6JAY7VkMfI6HdrmbR9etB6EDyIcpYP2rVeac1h6mCDEtwnIiLfwn8foo9nshsu2b3Cs4GqBr826NvMW2DNwjOp+VOyxp6N5rGeX4cfpyN6818nvm9Dv3eLPwh+QDuxx2Vywc7hvy4ifhKFNZvc7RbuA+zkunMooxpdLNYxA/mRfdlOAP+B2hpvfv9EDCyqGlyGcNScxX4YfVj4y/NY0/2EfN/81zY3hoxGshsubxOVPwal3Q2Gn2odwfIbyzj0+hVsrwx+I9gFVbpBp6O3F8NOIm77BZznsAfhR5QNvL81NQMbgxypDezEUGuhB5ffXMFIf5yTjoWKRCW7pxyJ824FfXN9t8AFKVWkVC+y2mZhobnDgJq8ncAesqzA6WFpeedupdoR/1vV6XVP2RgABXuHI1cLhINQafC7qplOkyn/aNu6FMg0oMLEHD5f5xcMHpJucfGZJb07gXacb0mrps8cvGyA28voEA1xoPR4Ev8Mcu2x5OovizSWUqu3g97AYinSszh6Ohp+ZCE44cUQMd66ESBI0nVq7vbNUlH+dVzWTrKt4Hc+OiWydvdjmYhw99bvfxwkLnttSp1yxmR8Znhjj5foHzfDwNMIghQ80UAnQ0Pdm/FYm7INz+vLadoqO4lDv6lYx8dav6w0MKtqw0RiHYyQNcNDhPN1ElILprtYJF//yMid87aTPtNs3yuwegX3wSFnP6XGEDHvrRucO/A6B0HG4232ZsCN6PAkDBy9ULnoH76l4LPjRfaSeaiTgLnSBcW19OJJhyK/aieBxamVGsL0sgSIQ+nuenp8tFByltx3TbVOkfGMfUMZjNTO2owMdth3+SukaKc8Senmw8an2s64IbsFwDfrnqjBQKMslmS6TtgJu8YaX0Rp+QYFti4mIfFYeiYjrPNPCexJ2v+Z7aO12pksBbMX1YY4W+lxkjOZiUaDKibNwcr27qFX14TA8ulSKTc6YwnnbKe6mLqbfxU930FxF+FHvudCB2XLQt5F2SXYutSXsXdWZPV+A7acZyrm2de+CqOOTK0RmXnwMjm4njmktvLN7rzq9RQfwJ9FBnmvhXjtXXZbso5euwHK6j3IjeMQmbMtJxx0nm7exy5+Cd7zj7eTu00HFEe2SdCk6c33wHLyLcgtfteJ4fWak4fPtRvAYfGN7VLlnWLzU+XbuFDoJbaYlqncXITvoo/3i43gS57PPW8p9rzsxWwuPetslrZvhLu7XghU4l7qpBPYuv93+xJZVripGAHdKbIa3UuToLDvwo5pD+OzhVztUT5xlxJ8svHDZ+1h0l5RfLlc7OrGvrb9pRzmgXof7CSOCa6ffbGWfML33Nvtx5dbAlxaud7yFHJE5ilaL07+7BMDfHSWrIhxh2YIiQ2zQjHAu6NR5MWFV9B6VnUUHd00c3FVuV2PxiAh2aXQcLrf/CprDMQp3GHWu2M3E+x1dG11tJDL86IaHN4YSOH3k4X52kK9jMxP3yxHMuEdiLYhUdkTW7Xh93nIj9VFPz25+8Fe3T6D9EtRhNUxQZbm10pew5JBkBz/ePYNrnR2zcL4xQlovAr+2nR/ZEvy+5uhiK/3JxHdpLBxHGXOhKRasY+Wy3/o3h+qKj/Vj8FPsL4Afuwx7r1n4Cf+egv5FRYVXeIVXeIVXeIVXeIVXeIVXeIVXeIVXeIVXeIVXeIVXeIVXeIVXeIVXeIUX4Kf+V+TT7ETlhuDmjP8hoRHlZv46HZBW+bfRhHfKT4FX5afAq/JT4FX5KfBTlf8Fk0yFV3iFV3iFV/ib4adcLgn8pAvFenPgDOX/7gBZlZ8CrxcNFV7hX4T/ky0V4Cfa/4Bg5B5SadT2AAAAAElFTkSuQmCC';
    }

    // Visualizations
    function tokenURI(uint256 _tokenId, IFantomonTrainer _trainers) external view returns (string memory) {
        return tokenURIEmbeddable(_tokenId, _trainers, IMAGE_EMBED);
    }
    function tokenURIEmbeddable(uint256 _tokenId, IFantomonTrainer _trainers, bool _embed) public view returns (string memory) {
        string[34] memory parts;
        parts[0]  = '<svg preserveaspectratio="xMinYMin meet" style="width: 100%; height: 100%; transform: translate3d(0px, 0px, 0px);" viewbox="0 0 246 448" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><style>.header { fill: black; font-family: Courier; font-size: 16px; }</style><style>.base { fill: black; font-family: Courier; font-size: 16px; }</style><style>.trailer { fill: white; font-family: Courier; font-size: 12px; }</style><style>.trailerGen { fill: gold; font-family: Courier; font-size: 12px; }</style>';
        if (_embed) {
            parts[1]  = '<image x="0" y="0" width="246" height="448" href="';
            parts[2]  =     getImageURI(_tokenId, _trainers);
            parts[3]  = '"/>'
                        '<text x="123" y="25" text-anchor="middle" font-weight="bold" class="base">';
        } else {
            parts[1]  = '<defs> <linearGradient id="myGradient" gradientTransform="rotate(90)"><stop offset="5%" stop-color="';
            if (_trainers.getRarity(_tokenId) == 0) {
                parts[2]  =     COMMON_CARD;
            } else if (_trainers.getRarity(_tokenId) == 1) {
                parts[2]  =     RARE_CARD;
            } else if (_trainers.getRarity(_tokenId) == 2) {
                parts[2]  =     EPIC_CARD;
            } else {  // if _trainers.getRarity(_tokenId) == 3) {
                parts[2]  =     LEGENDARY_CARD;
            }
            parts[3]  = 'stroke:#120f16;stroke-width:4;fill-opacity:1.0"/><rect x="7" y="8" width="232" height="23" style="stroke:#120f16;stroke-width:1.5;fill-opacity:0.0"/><rect x="7" y="30" width="232" height="192" style="fill:url(#myGradient);stroke:#120f16;stroke-width:1.5;fill-opacity:1"/><rect x="7" y="222" width="232" height="128" style="stroke:#120f16;stroke-width:1.5;fill-opacity:0.0"/><rect x="11" y="226" width="224" height="120" style="stroke:#120f16;stroke-width:1.5;fill-opacity:0.0"/><rect x="7" y="351" width="232" height="90" style="stroke:#120f16;stroke-width:1.5;fill-opacity:1"/><text x="123" y="100" text-anchor="middle" font-weight="bold" class="base">Fantomon</text><text x="123" y="120" text-anchor="middle" font-weight="bold" class="base">Trainer</text><text x="123" y="140" text-anchor="middle" font-weight="bold" class="base">#';
            parts[4]  =     toString(_tokenId);
            parts[5]  = '</text><text x="123" y="160" text-anchor="middle" font-weight="bold" class="base">Avatar ';
            parts[6]  = getFace(_tokenId, _trainers);
            parts[7]  = '</text>'
                        '<text x="123" y="25" text-anchor="middle" font-weight="bold" class="base">';
        }
        parts[8]  =     getTrainerName(_tokenId, _trainers);
        parts[9]  = '</text>'
                    '<text x="14" y="243" font-weight="bold" class="base">'
                        'Kinship: ';
        parts[10]  =     getKinship(_tokenId, _trainers);
        parts[11]  = '</text>'
                    '<text x="14" y="262" font-weight="bold" class="base">'
                        'Flare: ';
        parts[12]  =    getFlare(_tokenId, _trainers);
        parts[13]  = '</text>'
                    '<text x="14" y="281" font-weight="bold" class="base">'
                        'Healing: ';
        parts[14] =     getHealing(_tokenId, _trainers);
        parts[15] = '</text>'
                    '<text x="14" y="300" font-weight="bold" class="base">'
                        'Courage: ';
        parts[16]  =    getCourage(_tokenId, _trainers);
        parts[17] = '</text>'
                    '<text x="14" y="319" class="base">'
                        'Wins: ';
        parts[18] =     getWins(_tokenId, _trainers);
        parts[19] = '</text>'
                    '<text x="14" y="338" class="base">'
                        'Losses: ';
        parts[20] =     getLosses(_tokenId, _trainers);
        parts[21] = '</text>'
                    '<text x="14" y="365" class="trailer">'
                        'Class: ';
        parts[22] =     getClass(_tokenId, _trainers);
        parts[23] = '</text>'
                    '<text x="15" y="380" class="trailer">'
                        'Homeworld: ';
        parts[24] =     getHomeworld(_tokenId, _trainers);
        parts[25] = '</text>'
                    '<text x="14" y="395" class="trailer">'
                        'Rarity: ';
        parts[26] =     getRarity(_tokenId, _trainers);
        parts[27] = '</text>'
                    '<text x="14" y="416" class="trailer">'
                        'Status: ';
        parts[28] =     getStatus(_tokenId, _trainers);
        if (_trainers.getStatus(_tokenId) == RESTING) {  // if RESTING, green box
            parts[29] = '</text><rect x="10" y="403" width="166" height="17" style="fill:lime;stroke:lime;stroke-width:2;fill-opacity:0.1;stroke-opacity:0.9" />';
        } else if (_trainers.getStatus(_tokenId) == PREPARING) {  // if PREPARING, yellow box
            parts[29] = '</text><rect x="10" y="403" width="210" height="17" style="fill:yellow;stroke:yellow;stroke-width:2;fill-opacity:0.1;stroke-opacity:0.9" />';
        } else if (_trainers.getStatus(_tokenId) == BATTLING) {  // if BATTLING, blue box
            parts[29] = '</text><rect x="10" y="403" width="123" height="17" style="fill:cyan;stroke:cyan;stroke-width:2;fill-opacity:0.1;stroke-opacity:0.9" />';
        } else if (_trainers.getStatus(_tokenId) == HEALING) {  // if HEALING, red box
            parts[29] = '</text><rect x="10" y="403" width="173" height="17" style="fill:red;stroke:red;stroke-width:2;fill-opacity:0.1;stroke-opacity:0.9" />';
        } else {  // if (_trainers.getStatus(_tokenId) == LOST) {  // if LOST, magenta box
            parts[29] = '</text><rect x="10" y="403" width="94" height="17" style="fill:magenta;stroke:magenta;stroke-width:2;fill-opacity:0.1;stroke-opacity:0.9" />';
        }
        parts[30] = '<text x="14" y="435" font-weight="bold" class="trailerGen">'
                        'Generation 1'
                    '</text>'
                    '<text x="232" y="435" text-anchor="end" class="trailer">#';
        parts[31] =     toString(_tokenId);
        parts[32] = '</text>';
        parts[33] = '</svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1],  parts[2],  parts[3],  parts[4],  parts[5],  parts[6],  parts[7],  parts[8]));
        output =               string(abi.encodePacked(output,   parts[9],  parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        output =               string(abi.encodePacked(output,   parts[17], parts[18], parts[19], parts[20], parts[21], parts[22], parts[23], parts[24]));
        output =               string(abi.encodePacked(output,   parts[25], parts[26], parts[27], parts[28], parts[29], parts[30], parts[31], parts[32]));
        output =               string(abi.encodePacked(output,   parts[33]));

        parts[0]  = '{"name":"';
        parts[1]  = getTrainerName(_tokenId, _trainers);
        parts[2]  = '", "trainerId":"';
        parts[3]  = toString(_tokenId);
        parts[4]  = '", "avatar":"';
        parts[5]  = getFace(_tokenId, _trainers);
        parts[6]  = '", "kinship": "';
        parts[7]  = getKinship(_tokenId, _trainers);
        parts[8]  = '", "flare": "';
        parts[9]  = getFlare(_tokenId, _trainers);
        parts[10]  = '", "healing": "';
        parts[11]  = getHealing(_tokenId, _trainers);
        parts[12] = '", "courage": "';
        parts[13] = getCourage(_tokenId, _trainers);
        parts[14] = '", "wins": "';
        parts[15] = getWins(_tokenId, _trainers);
        parts[16] = '", "losses": "';
        parts[17] = getLosses(_tokenId, _trainers);
        parts[18] = '", "class": "';
        parts[19] = getClass(_tokenId, _trainers);
        parts[20] = '", "homeworld": "';
        parts[21] = getHomeworld(_tokenId, _trainers);
        parts[22] = '", "rarity": "';
        parts[23] = getRarity(_tokenId, _trainers);
        parts[24] = '", "status":"';
        parts[25] = getStatus(_tokenId, _trainers);
        parts[26] = '", "generation": "1", ';

        string memory json = string(abi.encodePacked(parts[0], parts[1],  parts[2],  parts[3],  parts[4],  parts[5],  parts[6],  parts[7],  parts[8]));
        json =               string(abi.encodePacked(json,   parts[9],  parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        json =               string(abi.encodePacked(json,   parts[17], parts[18], parts[19], parts[20], parts[21], parts[22], parts[23], parts[24]));
        json =               string(abi.encodePacked(json,   parts[25], parts[26]));  //, parts[27], parts[28], parts[29], parts[30], parts[31]));
        json = Base64.encode(bytes(string(abi.encodePacked(json, '"description": "Fantomon Trainers are player profiles for the Fantomons Play-to-Earn game. Attributes (class, homeworld, rarity, and avatar#) are randomly chosen and stored on-chain. Stats are initialized to 1, wins and losses to 0, and can be increased via interactions in the Fantomon universe. Start playing at Fantomon.net", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
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
