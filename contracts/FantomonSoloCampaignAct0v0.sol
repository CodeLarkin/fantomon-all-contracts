/*
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {FantomonFunctions} from "./FantomonFunctions.sol";

contract FantomonSoloCampaignAct0v0 is ReentrancyGuard, Ownable {
    using FantomonFunctions for FantomonLib.Fmon;

    uint48 constant public MAX_XP = 1069420000000;  // XP at max level: 1069420 * 1E6
    uint256 constant private ONE_MIL = 1000000; // constant to avoid typos (like extra 0s)

    //uint8 constant private RESTING = 0;
    //uint8 constant private PREPARING = 1;
    uint8 constant private BATTLING = 2;
    //uint8 constant private HEALING = 3;
    //uint8 constant private LOST = 4;

    // TODO setter?
    //uint16 public constant MAX_ATTACKS = 20; // maximum attacks before a battle auto-ends
    uint8 public constant TEAM_SIZE = 4; // fantomons per trainer for a battle
    struct Team {
        bool   inBattle;
        uint16 fantomonId0;
        uint16 fantomonId1;
        uint16 fantomonId2;
        uint16 fantomonId3;
        // TODO test array of IDs for scalable contract code
    }

    struct Attack {
        uint8 fantomonIdx; // fantomon index on team (0..TEAM_SIZE)
        uint8 attackIdx;
        uint8 target;
    }
    mapping (uint256 => Team) teams_;

    FantomonRegistry public registry_;

    constructor(FantomonRegistry _registry) {
        registry_ = _registry;
    }

    function setRegistry(FantomonRegistry _registry) external onlyOwner {
        registry_ = _registry;
    }


    function isBattlingHere(uint256 _trainerId) internal returns (bool) {
        IFantomonTrainerInteractive ftNFT = registry_.ftNFT_();
        return (ftNFT.getStatus(_trainerId) == BATTLING && ftNFT.location_(_trainerId) == address(this));
    }

    function enter(uint256 _trainerId, uint256[] calldata _fantomons) external override onlyTrainerContract() {
        if (address(registry_.ftNFT_()) != msg.sender) revert OnlyTrainerContractCan(address(registry_.ftNFT_()), msg.sender);
        if (_fantomons.length != TEAM_SIZE) revert InvalidTeamSize(_fantomons.length, teamSize_);
        if (teams_[_trainerId].inBattle) revert AlreadyBattling(_trainerId);

        for (uint8 i; i < TEAM_SIZE;) {
            if (registry_.fmonNFT_().ownerOf(_fantomons[idx]) != msg.sender) revert NotYourFantomon(_fantomons[i]);

            unchecked { ++i; }
        }
        Team memory team = Team(true, _fantomons[0], _fantomons[1], _fantomons[2], _fantomons[3]);
        teams_[_trainerId] = team;

        emit EnteredBattle(_trainerId, team);
    }

    function _initNpcs(uint265 _trainerId, Team memory team) internal view returns (FantomonLib.Fmon[] memory) {
        FantomonLib.Fmon[] memory npcs = new FantomonLib.Fmon[](TEAM_SIZE);
        // TODO initialize npcs
        return npcs;
    }
    function _performAttack(uint256 _trainerId,
                            FantomonLib.Fmon memory _atkr,
                            FantomonLib.Fmon memory _defr,
                            uint8 _attackId) public view returns (uint48 _dmg) {

        if (_atkr.dmg >= _atkr.scaleHp() || _defr.dmg >= _defr.scaleHp()) revert AlreadyFainted();

        FantomonLib.Stats memory atkrStats = _atkr.scale();
        FantomonLib.Stats memory defrStats = _defr.scale();

        // attack info and stats
        uint8 atkId = _attackIndex == 0 ? atkr.attacks.attack0 : atkr.attacks.attack1;
        uint256 atkPwr = uint256(ATTACK_STATS[atkId]);
        //uint256 atkAcc = uint256(_attackIndex == 0 ? atkr.modifiers.attack0Acc : atkr.modifiers.attack1Acc);

            if (atkId < 12) {  // normal attack
                //uint48 def = fstore.getScaledStat(_defrFantomonId, 2);
                //console.log("NORMAL ATTACK");
                // FIXME make sure divides by 5 and 50 dont round!
                _dmg = uint48((((2*uint256(atkr.lvl)/5 + 2) * atkPwr * atkrStats.attack   * ONE_MIL) / (uint256((defrStats.defense) * 20)) + 2));
                //console.log("Base   A:%s,D:%s", atkr.base.attack, defr.base.defense);
                //console.log("Scaled A:%s,D:%s", atkrStats.attack, defrStats.defense);
            } else {  // special attack
                //uint48 def = fstore.getScaledStat(_defrFantomonId, 4);
                //console.log("SPECIAL ATTACK");
                _dmg = uint48((((2*uint256(atkr.lvl)/5 + 2) * atkPwr * atkrStats.spAttack * ONE_MIL) / (uint256((defrStats.spDefense) * 20)) + 2));
                //console.log("Base   A:%s,D:%s", atkr.base.spAttack, defr.base.spDefense);
                //console.log("Scaled A:%s,D:%s", atkrStats.spAttack, defrStats.spDefense);
            }
            //console.log("BaseHP: %s, ScaledHP: %s", defr.base.hp, defrStats.hp);
            //console.log("Damage already: %s, , Damage: %s", defr.dmg, dmg);
            //console.log("Damage: %s", dmg);
            //// First attack does half damage
            //if (aboutToStart_[_atkrTrainer]) {
            //    dmg = dmg / 2;
            //    aboutToStart_[_atkrTrainer] = false;
            //}
    }
    // Trainer performs a sequence of attacks.
    // Simulate the results of this attack sequence including automated NPC attacks.
    // Return:
    //     Player's Fantomons after attack sequence
    //     NPC's Fantomons after attack sequence
    function simulateAttackSequence(uint256 _trainerId, Attack[] calldata _attacks) public view returns (uint48[] memory _playerDmgs,
                                                                                                         uint48[] memory _playerMaxHps,
                                                                                                         uint48[] memory _npcDmgs,
                                                                                                         uint48[] memory _npcMaxHps) {
        // Return arrays
        _playerDmgs   = new uint48[](TEAM_SIZE);
        _playerMaxHps = new uint48[](TEAM_SIZE);
        _npcDmgs      = new uint48[](TEAM_SIZE);
        _npcMaxHps    = new uint48[](TEAM_SIZE);

        // Collect player mons from fstore
        IFantomonStore fstore = registry_.fstore_();
        Team memory team = teams_[_trainerId];

        uint256[] memory fantomonIds = new FantomonLib.Fmon[](TEAM_SIZE);
        fantomonIds[0] = team.fantomonId0;
        fantomonIds[1] = team.fantomonId1;
        fantomonIds[2] = team.fantomonId2;
        fantomonIds[3] = team.fantomonId3;

        FantomonLib.Fmon[] memory fmons = new FantomonLib.Fmon[](TEAM_SIZE);
        fmons[0] = fstore.fmon(team.fantomonId0);
        fmons[1] = fstore.fmon(team.fantomonId1);
        fmons[2] = fstore.fmon(team.fantomonId2);
        fmons[3] = fstore.fmon(team.fantomonId3);

        _playerMaxHPs[0] = fmons[0].scaleHp();
        _playerMaxHPs[1] = fmons[1].scaleHp();
        _playerMaxHPs[2] = fmons[2].scaleHp();
        _playerMaxHPs[3] = fmons[3].scaleHp();

        // Initialize NPC mons (or does this happen in enter()?) or retrieve presets
        FantomonLib.Fmon[] memory _npcs = initNpcs(_trainerId, team);
        _npcMaxHps[0] = _npcs[0].scaleHp();
        _npcMaxHps[1] = _npcs[1].scaleHp();
        _npcMaxHps[2] = _npcs[2].scaleHp();
        _npcMaxHps[3] = _npcs[3].scaleHp();

        // Loop over user's attacks. For each attack in the sequence:
        for (uint16 i; i < _attacks.length;) {
            Attack calldata attack = _attacks[i];
            // Get the Fantomon performing the attack
            FantomonLib.Fmon memory fmon = fmons[attack.fantomonIdx];
            uint256 fmonId = fantomonIds[attack.fantomonIdx];

            // Get the actual attack being performed
            uint8 attackId;
            if (attack.attackIdx >= 2) revert InvalidAttackIndex(attack.attackIdx);  // fmon can only have <= 2 attacks
            if (attack.attackIdx == 0) {
                attackId = fmon.attacks.attack0;
            } else {  // if (attack.attackIdx == 0) {
                attackId = fmon.attacks.attack1;
            }
            if (attack.target >= TEAM_SIZE) revert InvalidTarget(attack.target);  // fmon can only have <= 2 attacks

            // Calculate and apply damage to corresponding NPC mon
            uint48 dmg = _performAttack(_trainerId, fmon, _npcs[attack.target], attackId);
            _npcDmgs[attack.fantomonIdx].dmg += dmg;

            // Allow NPC to attack and apply damage to corresponding Player mon

            // TODO Different arg for _traineraid here since npc is attacking?
            // NPC chooses attacker, target, and attack (use random)
            uint8 npcAttacker = 0;  // random(...);
            uint8 fmonTarget = 0;  // random(...);
            uint8 npcAttackId = 0;  // random(...);  // from chosen NPC's 2 attacks
            dmg = _performAttack(_trainerId, _npcs[npcAttacker], fmons[fmonTarget], npcAttackId);
            _playerDmgs[fmonTarget].dmg += dmg;

            unchecked { ++i; }
        }
    }
    function performBattle(uint256 _trainerId, Attack[] calldata _attacks) external view returns (uint48[] memory _playerDmgs,
                                                                                                  uint48[] memory _playerMaxHps,
                                                                                                  uint48[] memory _npcDmgs,
                                                                                                  uint48[] memory _npcMaxHPs) {
        // Contract cannot perform a battle
        address sender = _msgSender();
        if (sender != tx.origin) revert ContractCannotBattle(sender);

        (_playerDmgs, _npcDmgs, _npcMaxHps) = simulateAttackSequence(_trainerId, _attacks);
        // Check results of battle:
        //     All NPCs dead = win, else loss
        bool win = true;
        for (uint i; i < TEAM_SIZE;) {
            if (_npcDmgs[i] < _npcMaxHPs[i]) {
                win = false;
                break;
            }
            unchecked { ++i; }
        }
        bool loss = true;
        for (uint i; i < TEAM_SIZE;) {
            if (_playerDmgs[i] < _playerMaxHPs[i]) {
                loss = false;
                break;
            }
            unchecked { ++i; }
        }
        // Apply damages to player mons
        // return win, loss

    }

    error ContractCannotBattle(address senderContract);
    error OnlyTrainerContractCan(address trainerContract, address wrongSender);
    error InvalidTeamSize(uint256 size, uint256 shouldbe);
    error AlreadyBattling(uint256 trainerId);
    error NotYourFantomon(uint256 fantomonId);
    error InvalidAttackIndex(uint8 invalid);
    error InvalidTarget(uint8 invalid);
    error AlreadyFainted();

    event EnteredBattle(uint256 trainerId, Team team);

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
