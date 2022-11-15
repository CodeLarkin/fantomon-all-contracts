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

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./FantomonTrainerGraphics.sol";
import "./IFantomon.sol";
import "./IFantomonLocation.sol";

contract FantomonTrainer is IFantomonTrainer, ERC721Enumerable, ReentrancyGuard, Ownable {

    //using SafeMath for uint;
    //using SafeMath for uint256;

    // Contract containing visualization logic for Fantomon Trainers
    FantomonTrainerGraphics graphics_;

    /**************************************************************************
     * High-level constants
     **************************************************************************/
    uint256 constant private PRICE = 10 ether;
    uint256 constant private MAX_MINT = 10;
    uint256 constant private SUPPLY_CAP = 10000;
    /* End high-level constants
     **************************************************************************/

    /**************************************************************************
    * Addresses, team, whiteli
     **************************************************************************/
    address private LARKIN = 0x14E8F54f35eE42Cdf436A19086659B34dA6D9D47;
    address private WATER  = 0x692b54A541eE5590F551E002b0967b7981fF36F5;
    mapping(address => bool) private isTeam_;
    mapping(address => bool) public isOnWhiteList_;
    /* End addresses, team, whiteli
     **************************************************************************/

    /**************************************************************************
     * Stats and attributes for all trainers
     **************************************************************************/
    mapping (uint256 => address) public location_;    // per tokenId
    mapping (uint256 => bool)    private named_;       // per tokenId
    mapping (string => bool)     public  nameTaken_;
    mapping (uint256 => string)  private trainerName_; // per tokenId

    mapping (uint256 => uint256) private kinship_;      // per tokenId
    mapping (uint256 => uint256) private flare_;        // per tokenId
    mapping (uint256 => uint256) private timeHealing_;  // per tokenId
    mapping (uint256 => uint256) private courage_;      // per tokenId

    mapping (uint256 => uint256) private wins_;         // per tokenId
    mapping (uint256 => uint256) private losses_;       // per tokenId

    mapping (uint256 => uint256) private timeLastInteraction_;  // per tokenId - what time did you last interact with a Fantomon
    mapping (uint256 => uint256) private timeEnteredRift_;      // per tokenId - what time did you last enter a HealingRift
    mapping (uint256 => uint256) private timeLastJourney_;      // per tokenId - what time did you last journey


    uint8 constant private RESTING   = 0;
    uint8 constant private PREPARING = 1;
    uint8 constant private BATTLING  = 2;
    uint8 constant private HEALING   = 3;
    uint8 constant private LOST      = 4;

    mapping (uint256 => uint8) private status_;      // per tokenId

    mapping (uint256 => uint8) private rarity_;      // per tokenId

    uint8 constant private NUM_TRAINER_CLASSES = 16;
    mapping (uint256 => uint8) private class_;  // per tokenId

    uint8 constant private NUM_TRAINER_FACES = 7;
    mapping (uint256 => uint8) private face_;  // per tokenId

    uint8 constant private NUM_WORLDS = 13;
    mapping (uint256 => uint8) private homeworld_;  // per tokenId
    /* Stats and attributes for all trainers
     **************************************************************************/

    /**************************************************************************
     * External enabled contracts
     **************************************************************************/
    mapping (address => bool) public fantomonsEnabled_;
    mapping (address => bool) public arenasEnabled_;
    mapping (address => bool) public healingRiftsEnabled_;
    /* End external enabled contracts
     **************************************************************************/


    /**************************************************************************
     * Modifiers
     **************************************************************************/
    modifier onlyOwnerOf(uint _tokenId) {
      require(msg.sender == ownerOf(_tokenId), "Only owner of that tokenId can do that");
      _;
    }
    modifier onlyTeam() {
        require(msg.sender == owner() || msg.sender == LARKIN || msg.sender == WATER, "Can't do that, you are not part of the team");
        _;
    }
    modifier onlyCurrentLocation(uint256 _tokenId) {
        require(location_[_tokenId] == msg.sender, "Only this trainer's current location can do this");
        _;
    }
    /* End modifiers
     **************************************************************************/

    /**************************************************************************
     * Getters
     **************************************************************************/
    // Simple getters for interface
    function getKinship(uint256 _tokenId) external view override returns (uint256) {
        return kinship_[_tokenId];
    }
    function getFlare(uint256 _tokenId) external view override returns (uint256) {
        return flare_[_tokenId];
    }
    function getCourage(uint256 _tokenId) external view override returns (uint256) {
        return courage_[_tokenId];
    }
    function getWins(uint256 _tokenId) external view override returns (uint256) {
        return wins_[_tokenId];
    }
    function getLosses(uint256 _tokenId) external view override returns (uint256) {
        return losses_[_tokenId];
    }
    function getStatus(uint256 _tokenId) external view override returns (uint8) {
        return status_[_tokenId];
    }
    function getRarity(uint256 _tokenId) external view override returns (uint8) {
        return rarity_[_tokenId];
    }
    function getClass(uint256 _tokenId) external view override returns (uint8) {
        return class_[_tokenId];
    }
    function getFace(uint256 _tokenId) external view override returns (uint8) {
        return face_[_tokenId];
    }
    function getHomeworld(uint256 _tokenId) external view override returns (uint8) {
        return homeworld_[_tokenId];
    }
    function getTrainerName(uint256 _tokenId) external view override returns (string memory) {
        if (named_[_tokenId]) {
            return trainerName_[_tokenId];
        } else {
            return "UNKNOWN TRAINER";
        }
    }
    // if not healing, return timehealing
    // if healing, return timehealing + timesinceenter
    function getFullTimeHealing(uint256 _tokenId) public view returns (uint256) {
        if (status_[_tokenId] == HEALING && healingRiftsEnabled_[location_[_tokenId]]) {
            return timeHealing_[_tokenId] + block.timestamp - timeEnteredRift_[_tokenId];
        } else {
            return timeHealing_[_tokenId];
        }
    }
    function getHealing(uint256 _tokenId) external view override returns (uint256) {
        require(_tokenId <= totalSupply(), "That tokenId has not yet been claimed");
        return 1 + (getFullTimeHealing(_tokenId) / 1 days);
    }
    /* End getters
     **************************************************************************/

    /**************************************************************************
     * Token URI: image and metadata construction
     **************************************************************************/
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return graphics_.tokenURI(_tokenId, IFantomonTrainer(this));
    }
    /* End token URI: image and metadata construction
     **************************************************************************/

    /**************************************************************************
     * Setters
     **************************************************************************/
    // onlyOwner setters
    function toggleTeam(address _addr) external onlyOwner {
        isTeam_[_addr] = !isTeam_[_addr];
    }
    // onlyTeam setters
    function toggleFantomons(address _addr) external onlyTeam {
        fantomonsEnabled_[_addr] = !fantomonsEnabled_[_addr];
    }
    function toggleArena(address _addr) external onlyTeam {
        arenasEnabled_[_addr] = !arenasEnabled_[_addr];
    }
    function toggleHealingRift(address _addr) external onlyTeam {
        healingRiftsEnabled_[_addr] = !healingRiftsEnabled_[_addr];
    }
    function setManyWhiteList(address[] memory _addr) external onlyTeam {
        for(uint i = 0; i < _addr.length; i++){
            isOnWhiteList_[_addr[i]] = true;
        }
    }

    // onlyOwnerOf(_tokenId) setters
    function setTrainerName(uint256 _tokenId, string memory _name) external onlyOwnerOf(_tokenId) {
        require(!nameTaken_[_name], "Name already taken, choose another");
        require(bytes(_name).length > 0 && bytes(_name).length <= 24, "Name empty or too long");
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("UNKNOWN TRAINER")), "Invalid name");
        trainerName_[_tokenId] = _name;
        nameTaken_[_name] = true;
        named_[_tokenId] = true;
    }
    /* End getters
     **************************************************************************/

    /**************************************************************************
     * Initialization functions
     **************************************************************************/
    function _initRarity(uint256 _tokenId) internal {
        uint256 rand = random("RARITY", _tokenId);
        uint256 randMod100 = rand % 100;
        if (randMod100 < 52) {
            rarity_[_tokenId] = 0;
        } else if (randMod100 < 85) {
            rarity_[_tokenId] = 1;
        } else if (randMod100 < 99) {
            rarity_[_tokenId] = 2;
        } else { //} else if (randMod100 > 99) {
            rarity_[_tokenId] = 3;
        }
    }
    function _initFace(uint256 _tokenId) internal {
        uint256 rand = random("FACE", _tokenId);
        face_[_tokenId] = uint8(rand % NUM_TRAINER_FACES);
    }
    function _initClass(uint256 _tokenId) internal {
        uint256 rand = random("CLASS", _tokenId);
        uint256 randMod10000 = rand % 10000;
        if (       randMod10000 < 1500) {
            class_[_tokenId] = 0;
        } else if (randMod10000 < 3000) {
            class_[_tokenId] = 1;
        } else if (randMod10000 < 4500) {
            class_[_tokenId] = 2;
        } else if (randMod10000 < 6000) {
            class_[_tokenId] = 3;
        } else if (randMod10000 < 6750) {
            class_[_tokenId] = 4;
        } else if (randMod10000 < 7500) {
            class_[_tokenId] = 5;
        } else if (randMod10000 < 8250) {
            class_[_tokenId] = 6;
        } else if (randMod10000 < 9000) {
            class_[_tokenId] = 7;
        } else if (randMod10000 < 9225) {
            class_[_tokenId] = 8;
        } else if (randMod10000 < 9450) {
            class_[_tokenId] = 9;
        } else if (randMod10000 < 9675) {
            class_[_tokenId] = 10;
        } else if (randMod10000 < 9900) {
            class_[_tokenId] = 11;
        } else if (randMod10000 < 9925) {
            class_[_tokenId] = 12;
        } else if (randMod10000 < 9950) {
            class_[_tokenId] = 13;
        } else if (randMod10000 < 9975) {
            class_[_tokenId] = 14;
        } else {
            class_[_tokenId] = 15;
        }
    }
    function _initHomeworld(uint256 _tokenId) internal {
        uint256 rand = random("HOMEWORLD", _tokenId);
        uint256 randMod1000 = rand % 1000;
        if (       randMod1000 < 120) {
            homeworld_[_tokenId] = 0;
        } else if (randMod1000 < 240) {
            homeworld_[_tokenId] = 1;
        } else if (randMod1000 < 360) {
            homeworld_[_tokenId] = 2;
        } else if (randMod1000 < 480) {
            homeworld_[_tokenId] = 3;
        } else if (randMod1000 < 600) {
            homeworld_[_tokenId] = 4;
        } else if (randMod1000 < 700) {
            homeworld_[_tokenId] = 5;
        } else if (randMod1000 < 800) {
            homeworld_[_tokenId] = 6;
        } else if (randMod1000 < 900) {
            homeworld_[_tokenId] = 7;
        } else if (randMod1000 < 930) {
            homeworld_[_tokenId] = 8;
        } else if (randMod1000 < 960) {
            homeworld_[_tokenId] = 9;
        } else if (randMod1000 < 990) {
            homeworld_[_tokenId] = 10;
        } else if (randMod1000 < 995) {
            homeworld_[_tokenId] = 11;
        } else {
            homeworld_[_tokenId] = 12;
        }
    }
    /* End initialization functions
     **************************************************************************/


    /**************************************************************************
     * Mint
     **************************************************************************/
    function mint(uint8 _amount) external nonReentrant payable {
        require(_amount > 0 && _amount <= MAX_MINT, "Invalid mint amount");
        require(totalSupply() + _amount <= SUPPLY_CAP, "Cant mint past 10K supply cap");
        uint8 paidAmount = _amount;
        if (isOnWhiteList_[msg.sender]) {
            paidAmount--;
        }
        require(msg.value == PRICE * paidAmount, "Wrong amount of FTM sent with mint");

        isOnWhiteList_[msg.sender] = false;

        for (uint8 i = 0; i < _amount; i++) {
            uint256 tokenId = totalSupply() + 1;

            kinship_[tokenId] = 1;
            flare_[tokenId]   = 1;
            courage_[tokenId] = 1;
            status_[tokenId] = RESTING;  // start at rest

            _initRarity(tokenId);
            _initFace(tokenId);
            _initClass(tokenId);
            _initHomeworld(tokenId);

            _safeMint(_msgSender(), tokenId);
        }
    }
    /* End mint
     **************************************************************************/

    /**************************************************************************
     * Trainer actions - performed by owner
     **************************************************************************/
    // Fantomon interactions
    function pet(uint256 _trainer, uint256 _fantomon, address _fantomonContract) external onlyOwnerOf(_trainer) nonReentrant {
        require(status_[_trainer] == RESTING, "Trainer busy");
        require(fantomonsEnabled_[_fantomonContract], "Can only interact with an enabled Fantomon contract");
        require(block.timestamp > timeLastInteraction_[_trainer] + 1 hours, "Can only interact with a fantomon once per hour");

        uint256[] memory petArgs = new uint256[](1);
        petArgs[0] = 0;  // pet
        IFantomon(_fantomonContract).interact(_trainer, _fantomon, petArgs);
        kinship_[_trainer]++;
        timeLastInteraction_[_trainer] = block.timestamp;
    }
    function play(uint256 _trainer, uint256 _fantomon, address _fantomonContract) external onlyOwnerOf(_trainer) nonReentrant {
        require(status_[_trainer] == RESTING, "Trainer busy");
        require(fantomonsEnabled_[_fantomonContract], "Can only interact with an enabled Fantomon contract");
        require(block.timestamp > timeLastInteraction_[_trainer] + 1 hours, "Can only interact with a fantomon once per hour");

        uint256[] memory playArgs = new uint256[](1);
        playArgs[0] = 1;  // play
        IFantomon(_fantomonContract).interact(_trainer, _fantomon, playArgs);
        kinship_[_trainer]++;
        timeLastInteraction_[_trainer] = block.timestamp;
    }
    function sing(uint256 _trainer, uint256 _fantomon, address _fantomonContract) external onlyOwnerOf(_trainer) nonReentrant {
        require(status_[_trainer] == RESTING, "Trainer busy");
        require(fantomonsEnabled_[_fantomonContract], "Can only interact with an enabled Fantomon contract");
        require(block.timestamp > timeLastInteraction_[_trainer] + 1 hours, "Can only interact with a fantomon once per hour");

        uint256[] memory singArgs = new uint256[](1);
        singArgs[0] = 2;  // sing
        IFantomon(_fantomonContract).interact(_trainer, _fantomon, singArgs);
        flare_[_trainer]++;
        timeLastInteraction_[_trainer] = block.timestamp;
    }

    // Travel - Arenas, HealingRifts, Journeys
    function enterArena(uint256 _tokenId, address _arena, uint256[] calldata _args) external onlyOwnerOf(_tokenId) nonReentrant {
        require(status_[_tokenId] == RESTING, "Trainer busy");

        status_[_tokenId] = PREPARING;  // preparing for battle

        location_[_tokenId] = _arena;
        IFantomonLocation(_arena).enter(_tokenId, _args);
    }
    function enterHealingRift(uint256 _tokenId, address _rifts, uint256[] calldata _args) external onlyOwnerOf(_tokenId) nonReentrant {
        require(status_[_tokenId] == RESTING, "Trainer busy");

        status_[_tokenId] = HEALING;  // treating wounds
        timeEnteredRift_[_tokenId] = block.timestamp;

        location_[_tokenId] = _rifts;
        IFantomonLocation(_rifts).enter(_tokenId, _args);
    }
    function enterJourney(uint256 _tokenId, address _journey, uint256[] calldata _args) external onlyOwnerOf(_tokenId) nonReentrant {
        require(status_[_tokenId] == RESTING, "Trainer busy");
        require(block.timestamp > timeLastJourney_[_tokenId] + 12 hours, "Can only journey once every 12 hours");

        status_[_tokenId] = LOST;  // treating wounds

        timeLastJourney_[_tokenId] = block.timestamp;
        location_[_tokenId] = _journey;
        IFantomonLocation(_journey).enter(_tokenId, _args);
    }

    function flee(uint256 _tokenId) external onlyOwnerOf(_tokenId) nonReentrant {
        if (status_[_tokenId] == BATTLING && arenasEnabled_[location_[_tokenId]]) {
            // If emergency flee during battle, loss
            losses_[_tokenId]++;
        } else if (status_[_tokenId] == HEALING && healingRiftsEnabled_[location_[_tokenId]]) {
            timeHealing_[_tokenId] += block.timestamp - timeEnteredRift_[_tokenId];
        }
        // call flee in location's contract, but allow it to fail, and proceed with cleanup
        IFantomonLocation(location_[_tokenId]).flee(_tokenId);

        status_[_tokenId] = RESTING;  // resting
        location_[_tokenId] = address(0);
    }
    function emergencyFlee(uint256 _tokenId) external onlyOwnerOf(_tokenId) {
        if (status_[_tokenId] == BATTLING && arenasEnabled_[location_[_tokenId]]) {
            // If emergency flee during battle, loss
            losses_[_tokenId]++;
        } else if (status_[_tokenId] == HEALING && healingRiftsEnabled_[location_[_tokenId]]) {
            timeHealing_[_tokenId] += block.timestamp - timeEnteredRift_[_tokenId];
        }
        status_[_tokenId] = RESTING;  // resting
        location_[_tokenId] = address(0);
        emit EmergencyFlee(_tokenId);
    }
    /* End trainer actions - performed by owner
     **************************************************************************/

    /**************************************************************************
     * Trainer actions - performed by location contract
     **************************************************************************/
    function _enterBattle(uint256 _tokenId) external onlyCurrentLocation(_tokenId) {
        require(status_[_tokenId] != BATTLING, "Already battling");
        status_[_tokenId] = BATTLING;  // in battle
    }
    // To be called by a location contract to cleanly leave after an action/event is complete
    function _leaveArena(uint256 _tokenId, bool _won) external onlyCurrentLocation(_tokenId) {
        require(status_[_tokenId] == PREPARING || status_[_tokenId] == BATTLING, "Can only do this if currently at an arena");
        if (status_[_tokenId] == BATTLING && arenasEnabled_[location_[_tokenId]]) {
            if (_won) {
                wins_[_tokenId]++;
            } else {
                losses_[_tokenId]++;
            }
        }
        status_[_tokenId] = RESTING;  // resting
        location_[_tokenId] = address(0);
    }
    function _leaveHealingRift(uint256 _tokenId) external onlyCurrentLocation(_tokenId) {
        require(status_[_tokenId] == HEALING, "Can only do this if currently treating wounds");
        if (healingRiftsEnabled_[location_[_tokenId]]) {
            timeHealing_[_tokenId] += block.timestamp - timeEnteredRift_[_tokenId];
        }
        status_[_tokenId] = RESTING;  // resting
        location_[_tokenId] = address(0);
    }
    function _leaveJourney(uint256 _tokenId) external onlyCurrentLocation(_tokenId) {
        require(status_[_tokenId] == LOST, "Can only do this if currently lost");
        courage_[_tokenId]++;
        status_[_tokenId] = RESTING;  // resting
        location_[_tokenId] = address(0);
    }
    // Called by an arena or journey to leave without updating stats (an arena tie, failed journey)
    function _leave(uint256 _tokenId) external onlyCurrentLocation(_tokenId) {
        require(status_[_tokenId] != HEALING, "Cannot leave via _leave() while healing");
        status_[_tokenId] = RESTING;  // resting
        location_[_tokenId] = address(0);
    }
    /* Trainer actions - performed by location contract
     **************************************************************************/


    /**************************************************************************
     * Payments
     **************************************************************************/
    function withdraw() external onlyTeam {
        uint256 halfBal = address(this).balance / 2;

        Address.sendValue(payable(LARKIN), halfBal);
        Address.sendValue(payable(WATER),  halfBal);
    }
    /* End payments
     **************************************************************************/


    /**************************************************************************
     * Helper functions
     **************************************************************************/
    function random(string memory _tag, uint256 _int0) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_tag, toString(_int0), toString(block.timestamp), msg.sender)));
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
    /* End helper functions
     **************************************************************************/

    // Constructor
    constructor(FantomonTrainerGraphics _graphics) ERC721("Fantomon Trainers Gen1 on FTM", "FTG1") Ownable() {
        graphics_ = _graphics;
        isTeam_[LARKIN] = true;
        isTeam_[WATER]  = true;
    }

    // Events
    event EmergencyFlee(uint256 tokenId);
}
