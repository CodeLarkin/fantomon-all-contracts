/*
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
*/
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import "./IFantomonRegistry.sol";
import "./IFantomonStore.sol";
import "./IFantomonRoyalties.sol";

import {FantomonFunctions} from "./FantomonFunctions.sol";

/**************************************************************************
 * Contract to expose Fantomon Feeding funtionality to the player
 * Owner sets the menu, player feeds, contract makes calls to FantomonStore
 * to commit Nutrient + XP + Lvl updates to Fmon storage.
 **************************************************************************/
contract FantomonFeeding is Ownable {

    using FantomonFunctions for FantomonLib.Fmon;
    using FantomonFunctions for FantomonLib.StatBoost;
    using FantomonFunctions for FantomonLib.Stats;

    uint48 constant public MAX_XP        = 1069420000000;  // XP at max level:         1069420 * 1E6
    uint48 constant public LVL25_XP      =   15625000000;  // XP to get to LVL25
    uint48 constant public LVL50_XP      =  125000000000;  // XP to get to LVL50
    uint48 constant public LVL75_XP      =  421875000000;  // XP to get to LVL75
    uint48 constant public MAX_NUTRIENTS =     300000000;  // Max combined stat nutrients: 300 * 1E6

    uint256 constant private ONE_MIL = 1000000; // constant to avoid typos (like extra 0s)

    IFantomonRegistry public registry_;

    ERC20[] public foods_;
    mapping(ERC20 => bool) public foodEnabled_;   // is a food enabled?
    mapping(ERC20 => uint8) public foodBurnMode_; // is a food burnable? 0=no (transfer to dead addr), 1=burnFrom(), 2=transfer then burn()
    mapping(ERC20 => FantomonLib.StatBoost[2]) public foodBoosts_;

    constructor(IFantomonRegistry _registry) {
        registry_ = _registry;
    }


    /**************************************************************************
     * Add/Change/Remove functions for owner to set the menu
     * (food contracts and their associated boosts).
     * Each food has 2 boost options that are selected via an arg to feed().
     **************************************************************************/
    function addFood(ERC20 _food, uint8 _burnMode,
                     uint48[2] memory _xpBoosts,       uint48[2] memory _hpBoosts,
                     uint48[2] memory _attackBoosts,   uint48[2] memory _defenseBoosts,
                     uint48[2] memory _spAttackBoosts, uint48[2] memory _spDefenseBoosts) external onlyOwner {


        require(address(_food) != address(0), "Food addr cant be 0");
        require(!foodEnabled_[_food], "Food already on menu");

        foods_.push(_food);
        foodEnabled_[_food] = true;
        foodBurnMode_[_food] = _burnMode;

        FantomonLib.StatBoost memory boost0;
        boost0.xp        = _xpBoosts[0];
        boost0.hp        = _hpBoosts[0];
        boost0.attack    = _attackBoosts[0];
        boost0.defense   = _defenseBoosts[0];
        boost0.spAttack  = _spAttackBoosts[0];
        boost0.spDefense = _spDefenseBoosts[0];
        foodBoosts_[_food][0] = boost0;

        FantomonLib.StatBoost memory boost1;
        boost1.xp        = _xpBoosts[1];
        boost1.hp        = _hpBoosts[1];
        boost1.attack    = _attackBoosts[1];
        boost1.defense   = _defenseBoosts[1];
        boost1.spAttack  = _spAttackBoosts[1];
        boost1.spDefense = _spDefenseBoosts[1];
        foodBoosts_[_food][1] = boost1;
    }

    function rmFood(ERC20 _food) external onlyOwner {
        require(foodEnabled_[_food], "Not on menu");
        foodEnabled_[_food] = false;
    }

    function changeFood(ERC20 _food, uint8 _burnMode,
                        uint48[2] memory _xpBoosts,       uint48[2] memory _hpBoosts,
                        uint48[2] memory _attackBoosts,   uint48[2] memory _defenseBoosts,
                        uint48[2] memory _spAttackBoosts, uint48[2] memory _spDefenseBoosts) external onlyOwner {

        require(foodEnabled_[_food], "Not on menu");
        foodBurnMode_[_food] = _burnMode;

        FantomonLib.StatBoost memory boost0;
        boost0.xp        = _xpBoosts[0];
        boost0.hp        = _hpBoosts[0];
        boost0.attack    = _attackBoosts[0];
        boost0.defense   = _defenseBoosts[0];
        boost0.spAttack  = _spAttackBoosts[0];
        boost0.spDefense = _spDefenseBoosts[0];
        foodBoosts_[_food][0] = boost0;

        FantomonLib.StatBoost memory boost1;
        boost1.xp        = _xpBoosts[1];
        boost1.hp        = _hpBoosts[1];
        boost1.attack    = _attackBoosts[1];
        boost1.defense   = _defenseBoosts[1];
        boost1.spAttack  = _spAttackBoosts[1];
        boost1.spDefense = _spDefenseBoosts[1];
        foodBoosts_[_food][1] = boost1;
    }

    /**************************************************************************
     * Feed an Fmon with an amount of the given food.
     * Select a boost mode/option (each food has 2 boost options)
     * and choose whether to force-feed if boost surpasses MAX_XP.
     * Call helper function to update royalties if Lvl 25/50/75/100 is reached.
     **************************************************************************/
    function feed(uint256 _tokenId, ERC20 _food, uint8 _mode, uint48 _amountNoDecimals, bool _force) external {
        IFantomonStore fstore = registry_.fstore_();

        require(msg.sender == registry_.fmonNFT_().ownerOf(_tokenId), "Only token owner can");
        require(_amountNoDecimals != 0, "0 invalid amount");
        require(foodEnabled_[_food], "Not on menu");

        // Get boost by applying amount+mode to menu item
        FantomonLib.StatBoost memory boost = foodBoosts_[_food][_mode].mul(_amountNoDecimals);
        // Get current/original XP and Nutrients
        (uint48 origXp,
         FantomonLib.Stats memory nutrients) = fstore.getXpNutrients(_tokenId);

        require(nutrients.sum() < MAX_NUTRIENTS || origXp < MAX_XP, "Already maxed!");

        uint48 newXp = origXp + boost.xp;
        require(_force || newXp <= MAX_XP, "Can only force-feed past MAX_XP");  // provide some buffer

        if (newXp > MAX_XP) {
            boost.xp = MAX_XP - origXp;
            newXp = MAX_XP;
        }

        // Update the royalties at special levels
        _updateRoyalties(_tokenId, origXp, newXp);

        // Normalize the boost (in case it exceeds max), and apply to Fmon storage
        fstore._boostXpNutrients(_tokenId, _normalizeNutrientBoost(nutrients, boost));

        // BURN BABY BURN!
        // ... approval requirement handled by ERC20 contract
        if (foodBurnMode_[_food] == 0) {
            _food.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _amountNoDecimals * (10**_food.decimals()));
        } else if (foodBurnMode_[_food] == 1) {
            ERC20Burnable(address(_food)).burnFrom(msg.sender, _amountNoDecimals * (10**_food.decimals()));
        } else if (foodBurnMode_[_food] == 2) {
            _food.transferFrom(msg.sender, address(this), _amountNoDecimals * (10**_food.decimals()));
            ERC20Burnable(address(_food)).burn(_amountNoDecimals * (10**_food.decimals()));
        }
    }

    /**************************************************************************
     * Helpers for feeding
     **************************************************************************/

    // Update the royalties at special levels
    function _updateRoyalties(uint256 _tokenId, uint48 _origXp, uint48 _newXp) internal {
        IFantomonRoyalties royalties = registry_.royalties_();
        address leveler = registry_.fmonNFT_().ownerOf(_tokenId);
        // Handle level up and special actions at special levels
        if (_origXp < LVL25_XP && _newXp >= LVL25_XP) {
            royalties.set25Receiver(_tokenId, leveler);
        }
        if (_origXp < LVL50_XP && _newXp >= LVL50_XP) {
            royalties.set50Receiver(_tokenId, leveler);
        }
        if (_origXp < LVL75_XP && _newXp >= LVL75_XP) {
            royalties.set75Receiver(_tokenId, leveler);
        }
        if (_origXp < MAX_XP && _newXp >= MAX_XP) {
            royalties.set100Receiver(_tokenId, leveler);
        }
    }
    // Normalize the boost (in case it exceeds max)
    function _normalizeNutrientBoost(FantomonLib.Stats memory _nutrients, FantomonLib.StatBoost memory _boost) internal pure returns (FantomonLib.StatBoost memory) {
        uint48 nutrientsLeft = MAX_NUTRIENTS - _nutrients.sum();
        // Nothing to do if no nutrients left to allocate
        if (nutrientsLeft > 0) {
            uint48 nutrientsFed = _boost.sum();  // sum of all nutrients in a boost
            if (nutrientsFed > nutrientsLeft) {
                // if this boost would pass max nutrients, don't let it!
                // get the ratio of the boost's nutrients to nutrients-left
                // and apply it to all boost elements
                _boost = _boost.applyRatio(nutrientsLeft, nutrientsFed);

                // Handle any leftovers from rounding division, make sure to add to one of the stats already being boosted
                nutrientsLeft = nutrientsLeft - _boost.sum();
                if (nutrientsLeft > 0) {
                    if (_boost.hp > 0) {
                        _boost.hp += nutrientsLeft;
                    } else if (_boost.attack > 0) {
                        _boost.attack += nutrientsLeft;
                    } else if (_boost.defense > 0) {
                        _boost.defense += nutrientsLeft;
                    } else if (_boost.spAttack > 0) {
                        _boost.spAttack += nutrientsLeft;
                    } else if (_boost.spDefense > 0) {
                        _boost.spDefense += nutrientsLeft;
                    }
                }
            }
            return _boost;
        } else {
            return FantomonLib.StatBoost(_boost.xp, 0, 0, 0, 0, 0);
        }
    }

    /**************************************************************************
     * Helper Getters for externally calculating a feed
     **************************************************************************/
    // Make-believe feed to see the impact it would have on an Fmon
    function mockFeed(uint256 _tokenId, ERC20 _food, uint8 _mode, uint48 _amount, bool _force) public view returns (FantomonLib.Fmon memory) {
        IFantomonStore fstore = registry_.fstore_();

        require(_amount != 0, "0 invalid amount");
        require(foodEnabled_[_food], "Not on menu");

        FantomonLib.StatBoost memory boost = foodBoosts_[_food][_mode].mul(_amount);
        FantomonLib.Fmon memory fmon = fstore.fmon(_tokenId);
        uint48 origXp = fmon.xp;
        FantomonLib.Stats memory nutrients = fmon.nutrients;

        require(nutrients.sum() < MAX_NUTRIENTS || origXp < MAX_XP, "Already maxed!");

        uint48 newXp = origXp + boost.xp;
        require(_force || newXp <= MAX_XP, "Can only force-feed past MAX_XP");  // provide some buffer

        if (newXp > MAX_XP) {
            boost.xp = MAX_XP - origXp;
        }
        return fmon.mockXpNutrientBoost(_normalizeNutrientBoost(nutrients, boost));
    }

    function scaledMock(uint256 _tokenId, ERC20 _food, uint8 _mode, uint48 _amount, bool _force) external view returns (FantomonLib.Fmon memory _mock, FantomonLib.Stats memory _scaled) {
        _mock = mockFeed(_tokenId, _food, _mode, _amount, _force);
        _scaled = _mock.scale();
    }

    // How much of a given food would it take to get to max XP?
    function foodToMaxXp(uint256 _tokenId, ERC20 _food, uint256 _mode) external view returns (uint48) {
        require(foodEnabled_[_food], "Not on menu");

        uint48 xpPerFood = foodBoosts_[_food][_mode].xp;
        uint48 xpLeft = MAX_XP - registry_.fstore_().getXp(_tokenId);

        return xpLeft / xpPerFood;
    }
}
