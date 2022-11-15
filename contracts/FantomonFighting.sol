import "@openzeppelin/contracts/access/Ownable.sol";

import "./IFantomonRegistry.sol";
import "./IFantomonStore.sol";

import "hardhat/console.sol";

contract FantomonFighting is Ownable {
    using FantomonLib for FantomonLib.Fmon;
    using FantomonLib for FantomonLib.StatBoost;
    using FantomonLib for FantomonLib.Stats;

    uint48 constant public MAX_XP      = 1069420000000;  // XP at max level:       1069420 * 1E6
    uint48 constant public LVL25_XP    =   15625000000;
    uint48 constant public LVL50_XP    =  125000000000;
    uint48 constant public LVL75_XP    =  421875000000;
    uint48 constant public MAX_MASTERY =     300000000;  // Max combined stat mastery: 300 * 1E6

    uint256 constant private ONE_MIL = 1000000; // constant to avoid typos (like extra 0s)

    IFantomonRegistry public registry_;

    FantomonLib.StatBoost public maxArenaBoost_;

    constructor(IFantomonRegistry _registry) {
        registry_ = _registry;

        maxArenaBoost_ = FantomonLib.StatBoost(uint48(100*ONE_MIL), uint48(10*ONE_MIL), uint48(10*ONE_MIL), uint48(10*ONE_MIL), uint48(10*ONE_MIL), uint48(10*ONE_MIL));
    }

    // maximum stat boost that an arena can apply to any
    function setMaxArenaBoost(uint48 _xp, uint48 _hp, uint48 _attack, uint48 _defense, uint48 _spAttack, uint48 _spDefense) external onlyOwner {
        maxArenaBoost_ = FantomonLib.StatBoost(_xp, _hp, _attack, _defense, _spAttack, _spDefense);
    }

    function boostXpMastery(uint256 _tokenId, FantomonLib.StatBoost memory _boost) external returns (bool _success) {
        IFantomonStore fstore = registry_.fstore_();

        require(registry_.ftNFT_().arenasEnabled_(msg.sender), "Can only take damage in an approved arena");

        (uint48 origXp,
         FantomonLib.Stats memory mastery) = fstore.getXpMastery(_tokenId);

        uint48 newXp = origXp + _boost.xp;

        //console.log("XPcur %s, XPnext %s", fstore.XP_PER_LEVEL(_newLvl-1), fstore.XP_PER_LEVEL(_newLvl));
        //console.log("TokenId %s", _tokenId);
        //console.log("XP newLvl %s, newLvl: %s", fstore.XP_PER_LEVEL(_newLvl-1), _newLvl);
        //console.log("XPcur %s, newLvl %s", XP_PER_LEVEL[_newLvl-1], _newLvl);
        //console.log("Amount: %s, newLvl: %s", _amount, _newLvl);
        //console.log("Cur XP: %s, boosted XP: %s", xp, newXp);

        // confirm that boost is within max boost range
        // if we have reached MAX_XP, don't boost anything
        _success = false;  // return val, will be updated below if there is actually something to boost
        if (origXp < MAX_XP) {
            _success = true;
        }
        if (newXp > MAX_XP) {
            _boost.xp = MAX_XP - origXp;
            newXp = MAX_XP;
        }

        _updateRoyalties(_tokenId, origXp, newXp);

        if (legalBoost(_boost)) {

            //console.log("MAX_STAT: %s", MAX_STAT);
            uint48 masteryLeft = MAX_MASTERY - mastery.sum();
            if (masteryLeft > 0) {
                uint48 masteryGained = _boost.sum();
                if (masteryGained > masteryLeft) {
                    _boost = _boost.div(masteryLeft).mul(masteryGained);

                    // Handle any leftovers from rounding division, make sure to add to one of the stats already being boosted
                    masteryLeft = masteryLeft - _boost.sum();
                    if (masteryLeft > 0) {
                        if (_boost.hp > 0) {
                            _boost.hp += masteryLeft;
                        } else if (_boost.attack > 0) {
                            _boost.attack += masteryLeft;
                        } else if (_boost.defense > 0) {
                            _boost.defense += masteryLeft;
                        } else if (_boost.spAttack > 0) {
                            _boost.spAttack += masteryLeft;
                        } else if (_boost.spDefense > 0) {
                            _boost.spDefense += masteryLeft;
                        }
                    }
                }
                _success = true;
            }
        }

        // If either XP or Mastery was updated, commit it to Fantomon contract
        if (_success) {
            fstore._boostXpMastery(_tokenId, _boost);
        }

    }

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

    function legalBoost(FantomonLib.StatBoost memory _boost) public view returns (bool) {
        return (_boost.xp <= maxArenaBoost_.xp && _boost.hp <= maxArenaBoost_.hp
                && _boost.attack   <= maxArenaBoost_.attack   && _boost.defense   <= maxArenaBoost_.defense
                && _boost.spAttack <= maxArenaBoost_.spAttack && _boost.spDefense <= maxArenaBoost_.spDefense);
    }


}
