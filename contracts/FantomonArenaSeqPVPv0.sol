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

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "./IFantomonLocation.sol";
import "./FantomonRegistry.sol";
import "./IFantomonStore.sol";
import "./IFantomonTrainerInteractive.sol";
import "./FantomonFighting.sol";

import {FantomonLib} from "./FantomonLib.sol";

import "hardhat/console.sol";

contract FantomonArenaSeqPVPv0 is IFantomonLocation, ReentrancyGuard, Ownable, VRFConsumerBaseV2 {

    /* Chainlink VRF values */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 VRF_SUBSCRIPTION_ID;

    // Fantom coordinators from https://docs.chain.link/docs/vrf-contracts/#configurations
    // Fantom Mainnet
    //address vrfCoordinator = 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634;
    // Fantom Testnet
    address VRF_COORDINATOR = 0xbd13f08b8352A3635218ab9418E340c60d6Eb418;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    // Fantom Mainnet
    //  4000 gwei Key Hash 0xb4797e686f9a1548b9a2e8c68988d74788e0c4af5899020fb0c47784af76ddfa
    // 10000 gwei Key Hash 0x5881eea62f9876043df723cf89f0c2bb6f950da25e9dfe66995c24f919c8f8ab
    // 20000 gwei Key Hash 0x64ae04e5dba58bc08ba2d53eb33fe95bf71f5002789692fe78fb3778f16121c9
    //bytes32 VRF_KEYHASH = 0x64ae04e5dba58bc08ba2d53eb33fe95bf71f5002789692fe78fb3778f16121c9;
    // Fantom Testnet 3000 gwei hash
    bytes32 VRF_KEYHASH = 0x121a143066e0f2f08b620784af77cccb35c6242460b4a8ee251b4b416abaebd4;

    // Fantom Mainnet LINK: 0x6f43ff82cca38001b6699a8ac47a2d0e66939407
    // Fantom Testnet LINK: 0xfaFedb041c0DD4fA2Dc0d87a6B0979Ee6FA7af5F
    // Testnet faucet: https://faucets.chain.link/fantom-testnet

    uint32 VRF_CALLBACK_GAS = 100000;
    // The default is 3, but you can set this higher.
    uint16 VRF_CONFIRMATIONS = 10;
    uint16 VRF_WORDS = 1;


    using FantomonLib for FantomonLib.Fmon;
    //using FantomonLib for FantomonLib.StatBoost;
    using FantomonLib for FantomonLib.Stats;

    // battle length (cooldown)?
    // just length between phases, moves?

    FantomonRegistry public registry_;

    uint8 constant public MAX_SEQUNCE_ATTACKS = 32;
    uint8 constant public MAX_TURNS = 50;

    uint48 constant public MAX_XP = 1069420000000;  // XP at max level: 1069420 * 1E6
    uint256 constant private ONE_MIL = 1000000; // constant to avoid typos (like extra 0s)

    uint8 public constant teamSize = 1; // fantomons per trainer for a battle

    //uint8 constant private RESTING = 0;
    //uint8 constant private PREPARING = 1;
    uint8 constant private TRAINER_BATTLING = 2;
    //uint8 constant private HEALING = 3;
    //uint8 constant private LOST = 4;

    enum Results { DNE, ONGOING, ATTACKER_WON, DEFENDER_WON, DRAW }
    enum PlayerStatus { IDLE, QUEUED, BATTLING }
    struct Battle {
        uint16 attacker;  // trainer
        uint16 defender;  // trainer
        bool exists;
        bool done;
        uint256 rand;  // set by Chainlink VRF callback
    }
    struct Player {
        PlayerStatus status;
        uint32 attackSeq;
        uint16 fantomon;
        uint16 foe;
        bool defender;
    }

    uint256 nextBattle; // battle index/ID
    mapping (uint256  => Battle) public battles_;  // indexed by battle ID
    mapping (uint256 => Player) public players_;

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
        return (ftNFT.getStatus(_trainer) == TRAINER_BATTLING && ftNFT.location_(_trainer) == address(this));
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

    function getAttackInSeq(uint256 _sequence, uint8 _seqIndex) returns (uint8) {
        return uint8((_sequence >> _seqIndex) && 1);
    }

    // Called by FantomonTrainer contract
    //     args[0]: attack sequence (interpreted as series of 0s and 1s indexing your fantomon's attack0 or attack1)
    //     args[1]: fantomon ID (your team)
    //     args[2]: trainer1 ID (target/attackee)
    function enter(uint256 _trainer0, uint256[] calldata _args) external override onlyTrainerContract() nonReentrant {
        if (_args.length < 2) {
            revert FantomonArenaSeqPVPv0_MissingAttacksAndTeam();
        } else if (_args.length < 3) {
            // args0 is attack sequence, arg1 is fantomon ID
            _enterQueue(_trainer0, _args[0], _args[1]);
        } else {
            // args0 is attack sequence, arg1 is fantomon ID, arg2 is target trainer ID
            _enterBattle(_trainer0, _args[0], _args[1], args[2]);
        }
    }

    function _enterQueue(uint256 _trainer, uint256 _attackSeq, uint256 _fantomon) internal {
        // TODO test gas with a memory version of player
        Player storage player = players_[_trainer];
        require(player.status == IDLE, "Trainer already on queue");

        player.status = QUEUED;
        player.attackSeq = uint32(_attackSeq);
        player.fantomon = uint16(_attackSeq);
        // Players who enter queue instead of attacking are "defenders"
        player.defender = true;

        // TODO test initialize via:
        // player = Player { QUEUED, uint32(_attackSeq), uint16(_attackSeq), 0, false }

        emit EnteredQueue(_trainer, _attackSeq, _fantomon);
    }

    function _enterBattle(uint256 _attacker, uint256 _attackSeq, uint256 _fantomon, uint256 _defender) internal {
        IFantomonTrainerInteractive ftNFT = registry_.ftNFT_();

        require(_attacker != _defender, "Can't battle yourself");

        Player memory player0 = players_[_attacker];
        Player memory player1 = players_[_defender];
        require(player0.status == IDLE, "Only an inactive attacker can attack a trainer in queue");
        require(player1.status == QUEUED, "Can only enter battle with a trainer in queue");


        // lock the two trainers into battle
        player0.status == BATTLING;
        player1.status == BATTLING;

        ftNFT._enterBattle(_attacker);
        ftNFT._enterBattle(_defender);

        // TODO check gas if use unchecked statement below instead of ++ above
        // unchecked {
        //     ++nextBattle;
        // }

        // TODO less gas (for storage read) if VRF values are in struct
        uint256 battleId = COORDINATOR.requestRandomWords(VRF_KEYHASH, VRF_SUBSCRIPTION_ID, VRF_CONFIRMATIONS, VRF_CALLBACK_GAS, VRF_WORDS);
        player0.battle = battleId;
        player1.battle = battleId;

        battles_[battleId] = Battle(_attacker, _defender, false, 0);

        // Make chainlink call for randomness
        // callback just stores randomness (read-only function says winner - winner executes battle and claims winnings)
        //     check to ensure attacker and defender are both here (have not fled) before finishing battle

        emit EnteredBattle(_attacker, _defender);
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        battles_[_requestId].done = true;
        battles_[_requestId].rand = _randomWords[0];
    }

    function getBattleResults(uint256 _battleId) returns (Results memory) {
        // TODO memory or storage?
        Battle storage battle = battles_[_battleId];

        // TODO just revert here instead of having DNE/ONGOING enums?
        if (!battle.exists) return DNE;
        if (!battle.done) return ONGOING;

        Battle storage attacker = players_[battle.attacker];
        Battle storage defender = players_[battle.defender];

        // Simulate battle and return results
        // TODO implement
        // Iterate over turns, simulate attacks, up to MAX_TURNS. Sequences are circular.
        for (uint8 i; i < 32; ) {
            // First attack is 0th (right-most) bit
            uint8 attack = 1 & (attacker.attackSeq >> i)
            uint8 defend = 1 & (defender.attackSeq >> i)

            simulateAttack(_battleId, uint16 _fmonAttacker, uint8 _attack, uint16 _fmonDefender);

            unchecked { ++i; }
        }
        // Once a team is dead, return
        return ATTACKER_WON;
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

    function _simulateAttack(uint256 _battleId, uint16 _fmonAttacker, uint8 _attack, uint16 _fmonDefender) internal returns (bool) {
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

        // TODO get 

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

        onQueue_[_trainer] = false;
        onQueue_[activeBattles_[_trainer]] = false;

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

    // Errors
    error FantomonArenaSeqPVPv0_MissingAttacksAndTeam();

    // Events
    event EnteredQueue(uint256 trainer, uint256 attackSeq, uint256 fantomon);
    event EnteredBattle(uint256 trainer, uint256 attackSeq, uint256 fantomon, uint256 defender);
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

