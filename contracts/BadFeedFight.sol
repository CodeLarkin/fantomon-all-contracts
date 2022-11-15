import "@openzeppelin/contracts/access/Ownable.sol";

import "./IFantomonRegistry.sol";
import "./IFantomonStore.sol";

import {FantomonLib} from "./FantomonLib.sol";

contract BadFeedFight is Ownable {

    uint256 constant private ONE_MIL     =       1000000; // constant to avoid typos (like extra 0s)
    uint48 constant public MAX_XP        = 1069420000000;  // XP at max level:       1069420 * 1E6
    uint48 constant public LVL25_XP      =   15625000000;
    uint48 constant public LVL50_XP      =  125000000000;
    uint48 constant public LVL75_XP      =  421875000000;
    uint48 constant public MAX_NUTRIENTS =     300000000;  // Max combined stat nutrients: 300 * 1E6
    uint48 constant public MAX_MASTERY   =     300000000;  // Max combined stat mastery: 300 * 1E6

    IFantomonRegistry public registry_;

    constructor(IFantomonRegistry _registry) {
        registry_ = _registry;
    }

    // test functions
    function feedBadXp(uint256 _tokenId) external {
        IFantomonStore fstore = registry_.fstore_();
        fstore._boostXpNutrients(_tokenId, FantomonLib.StatBoost(MAX_XP+1, 0, 0, 0, 0, 0));
    }
    function feedBadNutrients(uint256 _tokenId) external {
        IFantomonStore fstore = registry_.fstore_();
        fstore._boostXpNutrients(_tokenId, FantomonLib.StatBoost(1, 0, 0, 0, MAX_NUTRIENTS, MAX_NUTRIENTS));
    }

    // test functions
    function boostXpMasteryBadXp(uint256 _tokenId) external {
        IFantomonStore fstore = registry_.fstore_();
        fstore._boostXpMastery(_tokenId, FantomonLib.StatBoost(MAX_XP+1, 0, 0, 0, 0, 0));
    }
    function boostXpMasteryBadMastery(uint256 _tokenId) external {
        IFantomonStore fstore = registry_.fstore_();
        fstore._boostXpMastery(_tokenId, FantomonLib.StatBoost(1, MAX_MASTERY, MAX_MASTERY, 0, 0, 0));
    }

}
