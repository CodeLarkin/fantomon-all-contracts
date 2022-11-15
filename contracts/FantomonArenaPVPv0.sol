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
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./IFantomonLocation.sol";
import "./FantomonRegistry.sol";
import "./IFantomonStore.sol";
import "./IFantomonTrainerInteractive.sol";
import "./FantomonFighting.sol";

import {FantomonLib} from "./FantomonLib.sol";

import "hardhat/console.sol";

contract FantomonArenaPVPv0 is IFantomonLocation, ReentrancyGuard, Ownable {
    using FantomonLib for FantomonLib.Fmon;
    //using FantomonLib for FantomonLib.StatBoost;
    using FantomonLib for FantomonLib.Stats;

    // battle length (cooldown)?
    // just length between phases, moves?

    FantomonRegistry public registry_;

    uint48 constant public MAX_XP        = 1069420000000;  // XP at max level:         1069420 * 1E6

    uint256 constant private ONE_MIL = 1000000; // constant to avoid typos (like extra 0s)

    uint8 public constant teamSize = 1; // fantomons per trainer for a battle

    //uint8 constant private RESTING = 0;
    //uint8 constant private PREPARING = 1;
    uint8 constant private BATTLING = 2;
    //uint8 constant private HEALING = 3;
    //uint8 constant private LOST = 4;

    mapping (uint256 => bool) public onBench_;
    mapping (uint256 => uint256) public activeBattles_;  // mapping from trainer0 to trainer1 for each active battle
    mapping (uint256 => uint256[teamSize]) public lineups_;  // fantomons being battled
    mapping (uint256 => bool) public lineupLockedIn_;
    mapping (uint256 => bool) public turn_; // is it your turn_
    mapping (uint256 => bool) public aboutToStart_; // battle is ready to start

    bool public noHeal_;

    FantomonLib.StatBoost public boost_;

    modifier isBattling(uint256 _trainer) {
        require(activeBattles_[_trainer] != 0, "Trainer isn't currently battling");
        _;
    }
    modifier onlyTrainerOwner(uint256 _trainer) {
        require(registry_.ftNFT_().ownerOf(_trainer) == msg.sender, "You don't own that trainer");
        _;
    }
    modifier onlyTrainerContract() {
        require(address(registry_.ftNFT_()) == msg.sender, "Only the Trainer contract can do that");
        _;
    }

    function isBattlingHere(uint256 _trainer) internal returns (bool) {
        IFantomonTrainerInteractive ftNFT = registry_.ftNFT_();
        return (ftNFT.getStatus(_trainer) == BATTLING && ftNFT.location_(_trainer) == address(this));
    }

    // returns whether noFlee
    // TODO consider uint16s for trainer ids
    function noFleeElseEnd(uint256 _trainer0, uint256 _trainer1) internal returns (bool) {
        IFantomonTrainerInteractive ftNFT = registry_.ftNFT_();
        if (!isBattlingHere(_trainer0)) {
            if (isBattlingHere(_trainer1)) {
                ftNFT._leaveArena(_trainer1, true);
            }
            _postBattleCleanup(_trainer1, _trainer0);
            return false;
        } else if (!isBattlingHere(_trainer1)) {
            if (isBattlingHere(_trainer0)) {
                ftNFT._leaveArena(_trainer0, true);
            }
            _postBattleCleanup(_trainer0, _trainer1);
            return false;
        }
        return true;
    }

    //modifier notBattling(uint256 trainer) {
    //    require(activeBattles_[trainer] == 0, "Trainer is already battling");
    //    _;
    //}
    constructor (FantomonRegistry _registry) {
        registry_ = _registry;
        boost_ = FantomonLib.StatBoost(uint48(100*ONE_MIL), uint48(10*ONE_MIL), uint48(10*ONE_MIL), uint48(10*ONE_MIL), uint48(10*ONE_MIL), uint48(10*ONE_MIL));
    }
    function toggleHeal() external onlyOwner {
        noHeal_ = !noHeal_;
    }
    function setBoost(uint48 _xp, uint48 _hp, uint48 _attack, uint48 _defense, uint48 _spAttack, uint48 _spDefense) external onlyOwner {
        boost_ = FantomonLib.StatBoost(_xp, _hp, _attack, _defense, _spAttack, _spDefense);
    }

    // args[0]: if 0, enter bench, else this arg is trainer1 ID (attackee)
    function enter(uint256 _trainer0, uint256[] calldata _args) external override onlyTrainerContract() nonReentrant {
        if (_args.length == 0 || _args[0] == 0) {
            _enterBench(_trainer0);
        } else {
            // nonzero _args[0] is attackee trainerId
            uint256 trainer1 = _args[0];
            _enterBattle(_trainer0, trainer1);
        }
    }

    function _enterBench(uint256 _trainer) internal {
        require(!onBench_[_trainer], "Trainer already on bench");
        require(activeBattles_[_trainer] == 0, "Trainer is battling, can't enter bench");
        onBench_[_trainer] = true;
        emit EnteredBench(_trainer);
    }

    function _enterBattle(uint256 _trainer0, uint256 _trainer1) internal {
        IFantomonTrainerInteractive ftNFT = registry_.ftNFT_();

        require(_trainer0 != _trainer1, "Can't battle yourself");
        require(activeBattles_[_trainer0] == 0 && activeBattles_[_trainer1] == 0, "Only two inactive trainers can enter battle");
        require(onBench_[_trainer1], "Can only enter battle with a trainer on bench");

        onBench_[_trainer1] = false;

        ftNFT._enterBattle(_trainer0);
        ftNFT._enterBattle(_trainer1);
        // lock the two trainers into battle
        activeBattles_[_trainer0] = _trainer1;
        activeBattles_[_trainer1] = _trainer0;
        // The trainer who was on the bench gets second pick (advantage)
        turn_[_trainer0] = true;
        turn_[_trainer1] = false;

        emit EnteredBattle(_trainer0, _trainer1);
    }

    function chooseTeam(uint256 _trainer, uint256[] memory _fantomons) public onlyTrainerOwner(_trainer) isBattling(_trainer) nonReentrant {
        if (!noFleeElseEnd(_trainer, activeBattles_[_trainer])) {
            return;
        }
        require(turn_[_trainer], "Not your turn_");
        require(!lineupLockedIn_[_trainer], "Already locked in team");
        require(_fantomons.length == teamSize, "Chose too many fantomons for your team");

        for (uint8 idx; idx < _fantomons.length; idx++) {
            require(registry_.fmonNFT_().ownerOf(_fantomons[idx]) == msg.sender, "You don't own that fantomon");
            //require(fantomons_.getInCombat(, "You don't own that fantomon");
        }
        //for (uint8 tokenId; tokenId < _fantomons.length; tokenId++) {
        //    fantomons_.enterCombat(tokenId);
        //}

        // TODO need to do this per-element copy??
        for (uint8 idx; idx < _fantomons.length; idx++) {
            lineups_[_trainer][idx] = _fantomons[idx];
        }
        lineupLockedIn_[_trainer] = true;

        // opponent's turn_
        nextTurn(_trainer);

        if (lineupLockedIn_[activeBattles_[_trainer]]) {
            aboutToStart_[activeBattles_[_trainer]] = true;
        }

        emit TeamLockedIn(_trainer);
    }

    function nextTurn(uint256 _trainer) internal {
        // toggle turn_ bool for each trainer!
        turn_[_trainer] = !turn_[_trainer];
        turn_[activeBattles_[_trainer]] = !turn_[activeBattles_[_trainer]];
    }

    /* _atkrFantomon and _defrFantomon are fantomon indexes into each trainer's chosen lineup
     */
    function attack(uint256 _atkrTrainer, uint256 _atkrFantomon, uint256 _defrFantomon, uint256 _attackIndex) public onlyTrainerOwner(_atkrTrainer) isBattling(_atkrTrainer) nonReentrant {
        if (!noFleeElseEnd(_atkrTrainer, activeBattles_[_atkrTrainer])) {
            return;
        }
        require(turn_[_atkrTrainer], "Not your turn_");
        require(_atkrFantomon < teamSize && _defrFantomon < teamSize, "That fantomon index is larger than lineup size");

        uint256 atkrFantomonId = lineups_[_atkrTrainer][_atkrFantomon];
        uint256 defrFantomonId = lineups_[activeBattles_[_atkrTrainer]][_defrFantomon];

        uint8 atkId = _performAttack(_atkrTrainer, atkrFantomonId, defrFantomonId, _attackIndex);

        nextTurn(_atkrTrainer);
        emit Attacked(_atkrTrainer, atkId);

        // if the attacked pokemon fainted, check if that trainer's whole team fainted
        // if so, end battle
        if (allFainted(activeBattles_[_atkrTrainer])) {
            // TODO don't end battle until all fantomons in lineup have fainted
            _endBattle(_atkrTrainer);
        }
    }

    function allFainted(uint256 _trainer) internal returns (bool) {
        IFantomonStore fstore = registry_.fstore_();
        for (uint8 id; id < lineups_[_trainer].length; id++) {
            if (!fstore.fainted(lineups_[_trainer][id])) {
                return false;
            }
        }
        return true;
    }

    // attackIndex uint8
    function _performAttack(uint256 _atkrTrainer, uint256 _atkrFantomonId, uint256 _defrFantomonId, uint256 _attackIndex) internal returns (uint8) {
        IFantomonStore fstore = registry_.fstore_();
        require(!fstore.fainted(_atkrFantomonId) && !fstore.fainted(_defrFantomonId), "Fainted Fantomons cant attack/defend");

        FantomonLib.Fmon memory atkr = fstore.fmon(_atkrFantomonId);
        //FantomonLib.Fmon memory defr = fstore.fmon(_defrFantomonId);

        FantomonLib.Stats memory atkrStats = atkr.scale();
        FantomonLib.Stats memory defrStats = fstore.getScaledStats(_defrFantomonId);

        // atkr
        // attack
        // attack0 or 1
        // attack0Pwr or 1
        // lvl

        // defr
        // defense


        // attack info and stats
        uint8 atkId = _attackIndex == 0 ? atkr.attacks.attack0 : atkr.attacks.attack1;
        uint256 atkPwr = uint256(ATTACK_STATS[atkId]);
        //uint256 atkAcc = uint256(_attackIndex == 0 ? atkr.modifiers.attack0Acc : atkr.modifiers.attack1Acc);

        //console.log("ATTACK:%s", atkId);
        //console.log("APWR:%s, A0PWR:%s, A1PWR:%s", atkPwr, atkr.modifiers.attack0Pwr, atkr.modifiers.attack1Pwr);
        //if ((random("ATK", atkId, msg.sender) % 100) < atkAcc) { // attack succeeds
        if (true) { // attack succeeds
            //console.log("LVL:%s,atkPWR:%s", atkr.lvl, atkPwr);
            // determine the damage based on attack and attacker and defender stats
            uint48 dmg;
            if (atkId < 12) {  // normal attack
                //uint48 def = fstore.getScaledStat(_defrFantomonId, 2);
                //console.log("NORMAL ATTACK");
                // FIXME make sure divides by 5 and 50 dont round!
                dmg = uint48((((2*uint256(atkr.lvl)/5 + 2) * atkPwr * atkrStats.attack   * ONE_MIL) / (uint256((defrStats.defense) * 20)) + 2));
                //console.log("Base   A:%s,D:%s", atkr.base.attack, defr.base.defense);
                //console.log("Scaled A:%s,D:%s", atkrStats.attack, defrStats.defense);
            } else {  // special attack
                //uint48 def = fstore.getScaledStat(_defrFantomonId, 4);
                //console.log("SPECIAL ATTACK");
                dmg = uint48((((2*uint256(atkr.lvl)/5 + 2) * atkPwr * atkrStats.spAttack * ONE_MIL) / (uint256((defrStats.spDefense) * 20)) + 2));
                //console.log("Base   A:%s,D:%s", atkr.base.spAttack, defr.base.spDefense);
                //console.log("Scaled A:%s,D:%s", atkrStats.spAttack, defrStats.spDefense);
            }
            //console.log("BaseHP: %s, ScaledHP: %s", defr.base.hp, defrStats.hp);
            //console.log("Damage already: %s, , Damage: %s", defr.dmg, dmg);
            //console.log("Damage: %s", dmg);
            // First attack does half damage
            if (aboutToStart_[_atkrTrainer]) {
                dmg = dmg / 2;
                aboutToStart_[_atkrTrainer] = false;
            }

            fstore._takeDamage(_defrFantomonId, dmg);
            //if (fstore._takeDamage(_defrFantomonId, dmg)) {
            //    if (defr.attrs.species < 9) {
            //        console.log("LVL:%s,atkPWR:%s", atkr.lvl, atkPwr);
            //        console.log("ATTACK:%s", atkId);
            //        //console.log("APWR:%s, A0PWR:%s, A1PWR:%s", atkPwr, atkr.modifiers.attack0Pwr, atkr.modifiers.attack1Pwr);
            //        console.log("Atkr: %s, Defr: %s", _atkrFantomonId, _defrFantomonId);
            //        if (atkId < 12) {  // normal attack
            //            console.log("NORMAL ATTACK");
            //            console.log("Base   A:%s,D:%s", atkr.base.attack, defr.base.defense);
            //            console.log("Scaled A:%s,D:%s", atkrStats.attack, defrStats.defense);
            //        } else {
            //            console.log("SPECIAL ATTACK");
            //            console.log("Base   A:%s,D:%s", atkr.base.spAttack, defr.base.spDefense);
            //            console.log("Scaled A:%s,D:%s", atkrStats.spAttack, defrStats.spDefense);
            //        }
            //        console.log("BaseHP: %s, ScaledHP: %s", defr.base.hp, defrStats.hp);
            //        console.log("Damage already: %s, , Damage: %s", defr.dmg, dmg);
            //        console.log("Damage: %s", dmg);

            //    }
            //}
        }
        return atkId;
    }

    function forfeit(uint256 _trainer) public isBattling(_trainer) nonReentrant {
        _endBattle(activeBattles_[_trainer]);
    }

    function _endBattle(uint256 _winner) internal {
        IFantomonTrainerInteractive ftNFT = registry_.ftNFT_();

        uint256 loser = activeBattles_[_winner];

        ftNFT._leaveArena(_winner, true);
        ftNFT._leaveArena(loser, false);
        _postBattleCleanup(_winner, loser);
    }

    function _healAll(uint256 _trainer) internal {
        IFantomonStore fstore = registry_.fstore_();
        for (uint8 idx; idx < lineups_[_trainer].length; idx++) {
            uint256 fantomonId = lineups_[_trainer][idx];
            //console.log("ID: %s, DMG: %s", fantomonId, fstore.fmon(fantomonId).dmg);
            fstore._heal(fantomonId, fstore.fmon(fantomonId).dmg, true);
            //console.log("Done healing");
        }
    }
    function _boostWinner(uint256 _trainer) internal {
        IFantomonStore fstore = registry_.fstore_();
        FantomonFighting fighting = FantomonFighting(registry_.fighting_());

        for (uint8 idx; idx < lineups_[_trainer].length; idx++) {
            uint256 fantomonId = lineups_[_trainer][idx];
            if (!fstore.fainted(fantomonId)) {
                uint48 newXp = fstore.fmon(fantomonId).xp + boost_.xp;
                uint8 newLvl = 1;
                for (uint8 lvl = 1; lvl <= 100; lvl++) {
                    if (XP_PER_LEVEL[lvl-1] <= newXp && (lvl == 100 || XP_PER_LEVEL[lvl] > newXp)) {
                        newLvl = lvl;
                        break;
                    }
                }
                // FIXME what if an arena bug messes with the wrong Fantomon here bumps its stats obsurdly?
                fighting.boostXpMastery(fantomonId, boost_);
            }
        }
    }
    function _postBattleCleanup(uint256 _winner, uint256 _loser) internal {
        // Clear active battle information
        _boostWinner(_winner);
        if (!noHeal_) {
            //_healAll(_winner);
            _healAll(_loser);
        }
        activeBattles_[_winner] = 0;
        activeBattles_[_loser]  = 0;
        lineupLockedIn_[_winner] = false;
        lineupLockedIn_[_loser] = false;

        emit BattleOver(_winner, _loser);
    }

    // Exit gracefully - called by the FantomonTrainer contract
    // Lets you flee via the FantomonTrainer contract, but still
    // trigger cleanup here. Cleaner than emergencyFlee
    function flee(uint256 _trainer) external override onlyTrainerContract nonReentrant {
        uint256 winner = activeBattles_[_trainer];

        onBench_[_trainer] = false;
        onBench_[activeBattles_[_trainer]] = false;

        if (activeBattles_[winner] != 0) {
            registry_.ftNFT_()._leaveArena(winner, true);
            emit BattleOver(winner, _trainer);
        }
        _postBattleCleanup(winner, _trainer);
    }

    // Getters
    function combatInProgress(uint256 _trainer) public view returns (bool) {
        return (activeBattles_[_trainer] != 0) && lineupLockedIn_[_trainer] && lineupLockedIn_[activeBattles_[_trainer]];
    }

    function random(string memory _tag, uint256 _int0, address _sender) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_tag, _int0, block.timestamp, _sender)));
    }

    event EnteredBench(uint256 trainer);
    event EnteredBattle(uint256 trainer0, uint256 trainer1);
    event TeamLockedIn(uint256 trainer);
    event Attacked(uint256 trainer, uint8 attackIdx);
    event BattleOver(uint256 winner, uint256 loser);

    uint48[100] public XP_PER_LEVEL = [
                   0,
             8000000,
            27000000,
            64000000,
           125000000,
           216000000,
           343000000,
           512000000,
           729000000,
          1000000000,
          1331000000,
          1728000000,
          2197000000,
          2744000000,
          3375000000,
          4096000000,
          4913000000,
          5832000000,
          6859000000,
          8000000000,
          9261000000,
         10648000000,
         12167000000,
         13824000000,
         15625000000,
         17576000000,
         19683000000,
         21952000000,
         24389000000,
         27000000000,
         29791000000,
         32768000000,
         35937000000,
         39304000000,
         42875000000,
         46656000000,
         50653000000,
         54872000000,
         59319000000,
         64000000000,
         68921000000,
         74088000000,
         79507000000,
         85184000000,
         91125000000,
         97336000000,
        103823000000,
        110592000000,
        117649000000,
        125000000000,
        132651000000,
        140608000000,
        148877000000,
        157464000000,
        166375000000,
        175616000000,
        185193000000,
        195112000000,
        205379000000,
        216000000000,
        226981000000,
        238328000000,
        250047000000,
        262144000000,
        274625000000,
        287496000000,
        300763000000,
        314432000000,
        328509000000,
        343000000000,
        357911000000,
        373248000000,
        389017000000,
        405224000000,
        421875000000,
        438976000000,
        456533000000,
        474552000000,
        493039000000,
        512000000000,
        531441000000,
        551368000000,
        571787000000,
        592704000000,
        614125000000,
        636056000000,
        658503000000,
        681472000000,
        704969000000,
        729000000000,
        753571000000,
        778688000000,
        804357000000,
        830584000000,
        857375000000,
        884736000000,
        912673000000,
        941192000000,
        970299000000,
              MAX_XP
    ];
    uint16[24] private ATTACK_STATS = [


        // NORMAL ATTACKS
        // 30% = 10% each
         9, // "Dissolve"
        14, // "Force Dissolve"
        12, // "Smolder"
        // 15% = 5% each
        15, // "Trauma"
         5, // "Spit"
         9, // "Regenerate"
        //  4% = 1.33% each
        18, // "Echo"
        10, // "Bend Mind"
        20, // "Soul Burn"
        //  1% = 0.33% each
        15, // "Cosmic Impact"
        40, // "Heal"
        21, // "Kinetic Impact"
        // SPECIAL ATTACKS
        // 30% = 10% each
        25, // "Rejuvinate"
        30, // "Cosmic Orb"
        20, // "Cosmic Flash"
        // 15% = 5% each
        45, // "Kinetic Assault"
        50, // "Frenzy"
        35, // "Storm Flash"
        //  4% = 1.33% each
        80, // "Galaxy Bomb"
        55, // "Warp Strike"
        40, // "Gunk Barrage"
        //  1% = 0.33% each
        30, // "Revive"
        40, // "Shriek Torpedo"
        50  // "Chorus of Skulls"
    ];

}
