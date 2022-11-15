/*
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
*/
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IFantomonRegistry.sol";
import "./IFantomonTrainerInteractive.sol";
import "./IFantomonAttributes.sol";
import "./FantomonAttributes.sol";
import "./IFantomonStore.sol";

import {FantomonLib} from "./FantomonLib.sol";

/**************************************************************************
 * This contract handles all state changes to Fantomon stats & attributes.
 * Fantomon details are stored here, and hooks to update and retrieve that
 * info are here.
 **************************************************************************/
contract FantomonStore is IFantomonStore, Ownable {
    using FantomonLib for FantomonLib.Fmon;
    using FantomonLib for FantomonLib.Stats;

    uint48 constant public MAX_XP        = 1069420000000;  // XP at max level:         1069420 * 1E6
    uint48 constant public MAX_NUTRIENTS =     300000000;  // Max combined stat nutrients: 300 * 1E6

    IFantomonRegistry public registry_;

    IFantomonAttributes public attrs_;  // contract for initializing Fmons via stat/attr rolls

    mapping (uint256 => FantomonLib.Fmon) private fmonsInternal_;  // Fantomon stats and attributes

    mapping (uint256 => string) public names_;      // name per Fantomon
    mapping (string => bool)    public nameTaken_;  // is a name taken?

    constructor(IFantomonRegistry _registry) {
        registry_ = _registry;
        attrs_ = new FantomonAttributes();
    }

    function setRegistry(IFantomonRegistry _registry) external onlyOwner {
        registry_ = _registry;
    }

    /**************************************************************************
     * Fmon Initialization (via FantomonAttributes contract)
     **************************************************************************/
    function initStarterFmon(uint256 _tokenId, address _sender,
                             uint256 _courage, uint256 _healing, uint8 _choice) external {
        require(msg.sender == address(registry_.fmonNFT_()), "Only Fantomon contract can init Fmon storage");
        require(fmonsInternal_[_tokenId].lvl == 0, "Fmon already initialized");
        fmonsInternal_[_tokenId] = attrs_.randStarter(_tokenId, _sender, _courage, _healing, _choice);
    }

    function initFmon(uint256 _tokenId, address _sender,
                      uint8 _class,  uint8 _homeworld,
                      uint8 _rarity, uint256 _courage, uint256 _healing) external {
        require(msg.sender == address(registry_.fmonNFT_()), "Only Fantomon contract can init Fmon storage");
        require(fmonsInternal_[_tokenId].lvl == 0, "Fmon already initialized");
        fmonsInternal_[_tokenId] = attrs_.randFmon(_tokenId, _sender, _class, _homeworld, _rarity, _courage, _healing);
    }
    /* End Fmon Initialization
     **************************************************************************/

    /**************************************************************************
     * Getters (some redundant ones for convenient/low-fee access)
     **************************************************************************/
    function fmon(uint256 _tokenId) external view returns (FantomonLib.Fmon memory) {
        return fmonsInternal_[_tokenId];
    }
    function fainted(uint256 _tokenId) external view returns (bool) {
        return fmonsInternal_[_tokenId].dmg >= fmonsInternal_[_tokenId].scaleHp();
    }
    function getLvl(uint256 _tokenId) external view returns (uint8) {
        return fmonsInternal_[_tokenId].lvl;
    }
    function getMorph(uint256 _tokenId) external view returns (uint8) {
        return fmonsInternal_[_tokenId].morph;
    }
    function getXp(uint256 _tokenId) external view returns (uint48) {
        return fmonsInternal_[_tokenId].xp;
    }
    function getDmg(uint256 _tokenId) external view returns (uint48) {
        return fmonsInternal_[_tokenId].dmg;
    }
    function getXpNutrients(uint256 _tokenId) external view returns (uint48, FantomonLib.Stats memory) {
        return (fmonsInternal_[_tokenId].xp,
                fmonsInternal_[_tokenId].nutrients);
    }
    function getXpMastery(uint256 _tokenId) external view returns (uint48, FantomonLib.Stats memory) {
        return (fmonsInternal_[_tokenId].xp,
                fmonsInternal_[_tokenId].mastery);
    }
    function getHp(uint256 _tokenId) external view returns (uint48) {
        return fmonsInternal_[_tokenId].base.hp;
    }
    function getNutrients(uint256 _tokenId) external view returns (FantomonLib.Stats memory) {
        return fmonsInternal_[_tokenId].nutrients;
    }
    function getMastery(uint256 _tokenId) external view returns (FantomonLib.Stats memory) {
        return fmonsInternal_[_tokenId].mastery;
    }
    function getScaledStats(uint256 _tokenId) external view returns (FantomonLib.Stats memory) {
        return fmonsInternal_[_tokenId].scale();
    }
    function getAttributes(uint256 _tokenId) external view returns (FantomonLib.Attributes memory) {
        return fmonsInternal_[_tokenId].attrs;
    }
    function getSpecies(uint256 _tokenId) external view returns (uint8) {
        return fmonsInternal_[_tokenId].attrs.species;
    }
    function getModifiers(uint256 _tokenId) external view returns (FantomonLib.Modifiers memory) {
        return fmonsInternal_[_tokenId].modifiers;
    }
    function getAttacks(uint256 _tokenId) external view returns (FantomonLib.Attacks memory) {
        return fmonsInternal_[_tokenId].attacks;
    }
    /* End Getters
     **************************************************************************/

    /**************************************************************************
     * User Actions
     **************************************************************************/
    // Allow owner of a Fantomon to update its name within some bounds
    // Names are unique and <= 20 chars
    function setName(uint256 _tokenId, string memory _name) external {
        require(msg.sender == registry_.fmonNFT_().ownerOf(_tokenId), "Only token owner can");
        require(!nameTaken_[_name], "Name taken");
        require(bytes(_name).length > 0 && bytes(_name).length <= 20, "Bad name length");
        if (bytes(names_[_tokenId]).length != 0) {
            nameTaken_[names_[_tokenId]] = false;
        }
        names_[_tokenId] = _name;
        nameTaken_[_name] = true;
        emit Named(_tokenId);
    }
    /* End user Actions
     **************************************************************************/

    /**************************************************************************
     * Healing and Damage Logic
     **************************************************************************/
    // Arenas can damage Fantomons - reach DMG == HP (scaled) and Fmon Faints
    function _takeDamage(uint256 _tokenId, uint48 _dmg) external returns (bool) {
        require(registry_.ftNFT_().arenasEnabled_(msg.sender), "Can only take damage in an approved arena");
        FantomonLib.Fmon storage sfmon = fmonsInternal_[_tokenId];
        FantomonLib.Stats memory stats = sfmon.scale();

        if ((sfmon.dmg + _dmg) > stats.hp) {
            sfmon.dmg = stats.hp;  // set damage to the full SCALED HP of the fantomon
            emit Fainted(_tokenId);
            return true;   // fainted
        } else {
            sfmon.dmg += _dmg;
            return false;  // did not faint
        }
    }

    // Arenas and Trainer Interactions can heal Fantomons
    function _heal(uint256 _tokenId, uint48 _amount, bool _full) external returns (bool) {
        IFantomonTrainerInteractive ftNFT = registry_.ftNFT_();
        require(ftNFT.fantomonsEnabled_(msg.sender) || ftNFT.arenasEnabled_(msg.sender), "Can only be healed in an approved interaction/arena");

        FantomonLib.Fmon storage sfmon = fmonsInternal_[_tokenId];
        uint48 dmg = sfmon.dmg;

        require(dmg > 0, "Cant pet a full HP Fantomon");

        if (dmg == 0) {
            return false;
        }
        if (_full || dmg < _amount) {
            sfmon.dmg = 0;
        } else {
            sfmon.dmg -= _amount;
        }
        return true;
    }
    /* Healing and Damage Logic
     **************************************************************************/

    /**************************************************************************
     * Stat and Attribute Updates
     **************************************************************************/
    // Boost XP, Nutrients (and Lvl as a side-effect) - call from Feeding contract
    function _boostXpNutrients(uint256 _tokenId, FantomonLib.StatBoost memory _boost) external {
        require(msg.sender == registry_.feeding_(), "Only the FantomonFeeding contract can change Nutrients");
        fmonsInternal_[_tokenId].commitXpNutrientBoost(_boost); // checks max xp & nutrients
        emit Boosted(_tokenId);
    }

    // Boost XP, Mastery (and Lvl as a side-effect) - call from Fighting contract
    function _boostXpMastery(uint256 _tokenId, FantomonLib.StatBoost memory _boost) external {
        require(msg.sender == registry_.fighting_(), "Only the FantomonFighting contract can change Mastery");
        fmonsInternal_[_tokenId].commitXpMasteryBoost(_boost); // checks max xp & mastery
        emit Boosted(_tokenId);
    }

    // Learn an attack at the Dojo - change an existing attack or learn new ones - up to 4 total
    function _changeAttack(uint256 _tokenId, uint8 _slotIdx, uint8 _atkIdx) external {
        require(msg.sender == registry_.dojo_(), "Only the FantomonDojo contract can change attack");
        if (_slotIdx == 0) {
            fmonsInternal_[_tokenId].attacks.attack0 = _atkIdx;
            emit AttackLearned(_tokenId);
            return;
        } else if (_slotIdx == 1) {
            fmonsInternal_[_tokenId].attacks.attack1 = _atkIdx;
            emit AttackLearned(_tokenId);
            return;
        } else if (_slotIdx == 2) {
            fmonsInternal_[_tokenId].attacks.attack2 = _atkIdx;
            emit AttackLearned(_tokenId);
            return;
        } else if (_slotIdx == 3) {
            fmonsInternal_[_tokenId].attacks.attack3 = _atkIdx;
            emit AttackLearned(_tokenId);
            return;
        }
        require(false, "Invalid _slotIdx");
    }

    // Can morph at lvl 50
    function _morph(uint256 _tokenId) external {
        require(msg.sender == registry_.morphing_(), "Only the FantomonMorphing contract can morph");
        require(fmonsInternal_[_tokenId].xp >= 125000000000, "Must be lvl 50+ to morph");
        fmonsInternal_[_tokenId].morph++;
        emit Morph(_tokenId);
    }
    /* End stat and Attribute Updates
     **************************************************************************/

    // Events are intended to be used for keeping track of latest Fmon info
    // with tools like Covalent or TheGraph
    event Named(uint256 tokenId);
    event Fainted(uint256 tokenId);
    event Boosted(uint256 tokenId);
    event AttackLearned(uint256 tokenId);
    event Morph(uint256 tokenId);
}
