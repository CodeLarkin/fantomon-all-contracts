// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IFantomonAttributes.sol";

import {FantomonLib} from "./FantomonLib.sol";


/**************************************************************************
 * This contract is responsible for generating Fantomon
 * attributes and their corresponding Solidity structs on mint.
 **************************************************************************/
contract FantomonAttributes is IFantomonAttributes {

    mapping(uint8 => uint8) private numRelicsOfType;
    mapping(uint8 => uint8) private numAncientsOfType;
    mapping(uint8 => uint8[]) private relicsOfType;
    mapping(uint8 => uint8[]) private ancientsOfType;


    uint8[16] private trainerClassTypeBoosts_ = [
        7,  // Botanist            -> Plant
        7,  // Zoologist           -> Plant
        0,  // Hydrologist         -> Aqua
        5,  // Entomologist        -> Gunk
        5,  // Biochemist          -> Gunk
        3,  // Microbiologist      -> Demon
        0,  // Biotechnologist     -> Aqua
        3,  // Biomedical Engineer -> Demon
        6,  // Geneticist          -> Mineral
        2,  // Astrophysicist      -> Cosmic
        1,  // String Theorist     -> Chaos
        1,  // Quantum Physicist   -> Chaos
        4,  // Ent Mystic          -> Fairy
        4,  // Ent Theorist        -> Fairy
        2,  // Cosmic Explorer     -> Cosmic
        6   // Ancient Ent Master  -> Mineral
    ];
    uint8[13] private trainerWorldTypeBoosts_ = [
        5,  // Gunka               -> Gunk
        1,  // Sha'afta            -> Chaos
        0,  // Jiego               -> Plant
        5,  // Beck S68            -> Gunk
        5,  // Gem Z32             -> Aqua
        3,  // Junapla             -> Plant
        0,  // Strigah             -> Demon
        3,  // Mastazu             -> Chaos
        6,  // Clyve R24           -> Demon
        2,  // Larukin             -> Cosmic
        1,  // H-203               -> Aqua
        1,  // Ancient Territories -> Mineral
        4   // Relics Rock         -> Fairy
    ];

    FantomonLib.Stats[42] private BASE_SPECIES_STATS;

    uint24[14] private ESSENCE_VALUES = [
        // 40% = 20% each: x0.9
         900000 ,  // "Shy"
         900000 ,  // "Docile"
        // 49% =  7% each: x1.0
        1000000 ,  // "Alert"
        1000000 ,  // "Swift"
        1000000 ,  // "Nimble"
        1000000 ,  // "Agile"
        1000000 ,  // "Wild"
        1000000 ,  // "Sneaky"
        1000000 ,  // "Reckless"
        // 11% =  2.2% each: x1.1
        1100000 ,  // "Spunky"
        1100000 ,  // "Spirited"
        1100000 ,  // "Fiery"
        1100000 ,  // "Smart"
        1100000    // "Cosmic"
    ];


    constructor() {
        // Counts of species, relics and ancients of each type
        // numSpeciesOfType[0] = 10;
        // numSpeciesOfType[1] = 2;
        // numSpeciesOfType[2] = 4;
        // numSpeciesOfType[3] = 3;
        // numSpeciesOfType[4] = 6;
        // numSpeciesOfType[5] = 7;
        // numSpeciesOfType[6] = 2;
        // numSpeciesOfType[7] = 6;

        // speciesOfType[0] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        // speciesOfType[1] = [10, 11];
        // speciesOfType[2] = [12, 13, 14, 15];
        // speciesOfType[3] = [16, 17, 18];
        // speciesOfType[4] = [19, 20, 21, 22, 23, 24];
        // speciesOfType[5] = [25, 26, 27, 28, 29, 30, 31];
        // speciesOfType[6] = [32, 33];
        // speciesOfType[7] = [34, 35, 36, 37, 38, 39];

        numRelicsOfType[0] = 9;
        numRelicsOfType[1] = 1;
        numRelicsOfType[2] = 4;
        numRelicsOfType[3] = 3;
        numRelicsOfType[4] = 5;
        numRelicsOfType[5] = 7;
        numRelicsOfType[6] = 1;
        numRelicsOfType[7] = 5;

        relicsOfType[0] = [0, 1, 2, 3, 4, 5, 6, 7, 8];
        relicsOfType[1] = [10];
        relicsOfType[2] = [12, 13, 14, 15];
        relicsOfType[3] = [16, 17, 18];
        relicsOfType[4] = [19, 20, 21, 22, 23];
        relicsOfType[5] = [25, 26, 27, 28, 29, 30, 31];
        relicsOfType[6] = [32];
        relicsOfType[7] = [34, 35, 36, 37, 38];

        numAncientsOfType[0] = 1;
        numAncientsOfType[1] = 1;
        numAncientsOfType[2] = 0;
        numAncientsOfType[3] = 0;
        numAncientsOfType[4] = 1;
        numAncientsOfType[5] = 0;
        numAncientsOfType[6] = 1;
        numAncientsOfType[7] = 1;

        ancientsOfType[0] = [9];
        ancientsOfType[1] = [11];
        //ancientsOfType[2] = [];
        //ancientsOfType[3] = [];
        ancientsOfType[4] = [24];
        //ancientsOfType[5] = [];
        ancientsOfType[6] = [33];
        ancientsOfType[7] = [39];

        // Each Species has certain base stats that all Fantomons of that Species share
        //                                           HP         ATK        DEF       S.ATK      S.DEF     // SPEED
        BASE_SPECIES_STATS[ 0] = FantomonLib.Stats(40000000 , 30000000 , 25000000 , 50000000 , 32000000); // 40000000);  # Exotius            Total: 147000000
        BASE_SPECIES_STATS[ 1] = FantomonLib.Stats(46000000 , 45000000 , 32000000 , 50000000 , 40000000); // 45000000);  # Waroda             Total: 183000000
        BASE_SPECIES_STATS[ 2] = FantomonLib.Stats(10000000 , 35000000 , 15000000 , 35000000 , 20000000); // 15000000);  # Flamphy            Total:  85000000
        BASE_SPECIES_STATS[ 3] = FantomonLib.Stats(50000000 , 45000000 , 40000000 , 55000000 , 40000000); // 38000000);  # Buui               Total: 200000000
        BASE_SPECIES_STATS[ 4] = FantomonLib.Stats(24000000 , 32000000 , 12000000 , 54000000 , 30000000); // 35000000);  # Jilius             Total: 122000000
        BASE_SPECIES_STATS[ 5] = FantomonLib.Stats(20000000 , 25000000 , 25000000 , 45000000 , 20000000); // 35000000);  # Octmii             Total: 105000000
        BASE_SPECIES_STATS[ 6] = FantomonLib.Stats(25000000 , 32000000 , 20000000 , 45000000 , 28000000); // 10000000);  # Starfy             Total: 120000000
        BASE_SPECIES_STATS[ 7] = FantomonLib.Stats(50000000 , 35000000 , 13000000 , 33000000 , 13000000); // 15000000);  # Luupe              Total: 114000000
        BASE_SPECIES_STATS[ 8] = FantomonLib.Stats(30000000 , 38000000 , 38000000 , 48000000 , 25000000); // 25000000);  # Milius             Total: 149000000
        BASE_SPECIES_STATS[ 9] = FantomonLib.Stats(50000000 , 42000000 , 22000000 , 45000000 , 30000000); // 35000000);  # Shelfy  # Ancient  Total: 159000000
        BASE_SPECIES_STATS[10] = FantomonLib.Stats(38000000 , 29000000 , 28000000 , 45000000 , 29000000); // 26000000);  # Ephisto            Total: 139000000
        BASE_SPECIES_STATS[11] = FantomonLib.Stats(50000000 , 42000000 , 22000000 , 45000000 , 30000000); // 35000000);  # Kazaaba # Ancient  Total: 159000000
        BASE_SPECIES_STATS[12] = FantomonLib.Stats(40000000 , 35000000 , 20000000 , 55000000 , 35000000); // 35000000);  # Xatius             Total: 155000000
        BASE_SPECIES_STATS[13] = FantomonLib.Stats(28000000 , 40000000 , 18000000 , 54000000 , 29000000); // 24000000);  # Tapoc              Total: 139000000
        BASE_SPECIES_STATS[14] = FantomonLib.Stats(15000000 , 32000000 , 21000000 , 48000000 , 22000000); // 20000000);  # Slusa              Total: 108000000
        BASE_SPECIES_STATS[15] = FantomonLib.Stats(40000000 , 49000000 , 18000000 , 55000000 , 19000000); // 40000000);  # Cosmii             Total: 151000000
        BASE_SPECIES_STATS[16] = FantomonLib.Stats(32000000 , 28000000 , 28000000 , 44000000 , 24000000); // 10000000);  # Decro              Total: 126000000
        BASE_SPECIES_STATS[17] = FantomonLib.Stats(35000000 , 32000000 , 30000000 , 40000000 , 25000000); // 25000000);  # Merich             Total: 132000000
        BASE_SPECIES_STATS[18] = FantomonLib.Stats(38000000 , 40000000 , 15000000 , 52000000 , 22000000); // 20000000);  # Zeepuu             Total: 137000000
        BASE_SPECIES_STATS[19] = FantomonLib.Stats(30000000 , 38000000 , 20000000 , 42000000 , 20000000); // 25000000);  # Huffly             Total: 120000000
        BASE_SPECIES_STATS[20] = FantomonLib.Stats(32000000 , 36000000 , 30000000 , 38000000 , 32000000); // 15000000);  # Munsa              Total: 138000000
        BASE_SPECIES_STATS[21] = FantomonLib.Stats(26000000 , 34000000 , 20000000 , 42000000 , 20000000); // 20000000);  # Fenii              Total: 112000000
        BASE_SPECIES_STATS[22] = FantomonLib.Stats(20000000 , 40000000 , 18000000 , 42000000 , 25000000); // 15000000);  # Fleppa             Total: 115000000
        BASE_SPECIES_STATS[23] = FantomonLib.Stats(48000000 , 40000000 , 15000000 , 48000000 , 35000000); // 45000000);  # Mii                Total: 156000000
        BASE_SPECIES_STATS[24] = FantomonLib.Stats(50000000 , 35000000 , 45000000 , 50000000 , 42000000); // 43000000);  # Jixpi   # Ancient  Total: 192000000
        BASE_SPECIES_STATS[25] = FantomonLib.Stats(38000000 , 30000000 , 30000000 , 30000000 , 15000000); // 25000000);  # Kaibu              Total: 113000000
        BASE_SPECIES_STATS[26] = FantomonLib.Stats(23000000 , 30000000 , 25000000 , 45000000 , 20000000); // 35000000);  # Koob               Total: 113000000
        BASE_SPECIES_STATS[27] = FantomonLib.Stats(25000000 , 25000000 , 15000000 , 55000000 , 30000000); // 15000000);  # Woobek             Total: 120000000
        BASE_SPECIES_STATS[28] = FantomonLib.Stats(20000000 , 25000000 , 25000000 , 55000000 , 30000000); // 15000000);  # Googa              Total: 125000000
        BASE_SPECIES_STATS[29] = FantomonLib.Stats(20000000 , 35000000 , 15000000 , 55000000 , 30000000); // 25000000);  # Piniju             Total: 125000000
        BASE_SPECIES_STATS[30] = FantomonLib.Stats(10000000 , 32000000 , 14000000 , 40000000 , 10000000); //  5000000);  # Gubba              Total:  76000000
        BASE_SPECIES_STATS[31] = FantomonLib.Stats(25000000 , 42000000 , 28000000 , 39000000 , 25000000); // 14000000);  # Belkezor           Total: 129000000
        BASE_SPECIES_STATS[32] = FantomonLib.Stats(25000000 , 32000000 , 24000000 , 50000000 , 24000000); // 20000000);  # Meph               Total: 125000000
        BASE_SPECIES_STATS[33] = FantomonLib.Stats(50000000 , 22000000 , 38000000 , 45000000 , 45000000); // 12000000);  # Relixia # Ancient  Total: 170000000
        BASE_SPECIES_STATS[34] = FantomonLib.Stats(26000000 , 37000000 , 29000000 , 40000000 , 30000000); // 15000000);  # Shrooto            Total: 132000000
        BASE_SPECIES_STATS[35] = FantomonLib.Stats(39000000 , 38000000 , 25000000 , 45000000 , 23000000); // 25000000);  # Sphin              Total: 140000000
        BASE_SPECIES_STATS[36] = FantomonLib.Stats(32000000 , 33000000 , 25000000 , 44000000 , 24000000); // 22000000);  # Rooto              Total: 128000000
        BASE_SPECIES_STATS[37] = FantomonLib.Stats(28000000 , 40000000 , 18000000 , 54000000 , 29000000); // 24000000);  # Icaray             Total: 139000000
        BASE_SPECIES_STATS[38] = FantomonLib.Stats(35000000 , 40000000 , 18000000 , 49000000 , 25000000); // 18000000);  # Brutu              Total: 137000000
        BASE_SPECIES_STATS[39] = FantomonLib.Stats(30000000 , 35000000 , 30000000 , 40000000 , 15000000); // 25000000);  # Grongel # Ancient  Total: 120000000
        BASE_SPECIES_STATS[40] = FantomonLib.Stats(35000000 , 40000000 , 30000000 , 40000000 , 20000000); // 25000000);  # Larik   # Starter  Total: 135000000
        BASE_SPECIES_STATS[41] = FantomonLib.Stats(35000000 , 30000000 , 20000000 , 50000000 , 30000000); // 25000000);  # Gretto  # Starter  Total: 135000000
        //                                           HP         ATK        DEF       S.ATK      S.DEF     // SPEED
    }



    /* Type choice probabilities here do not include Starters which of course are chosen by the user.

     * Each species has 3.2% base probability except for certain reduced (rare) species.
     * This does not take Relic versus Ancient into account yet.

     * Trainer class and homeworld then each provide a 2% boost to some type.

     * The probability of getting a certain type is the 3.2% x NUM_SPECIES_IN_TYPE,
     * and then is halved or quartered for certain more-rare species.

     * So, since there are 10 Aqua Ents, 3.2% x 10 = 32%.
     * If you have a hydrologist trainer that ends up being a probability 32% + 2% = 34% that you mint an Aqua Ent.
    */
    function randType(uint256 _fantomonId, uint8 _trainerClass, uint8 _trainerWorld, address _sender) internal view returns (uint8) {
        uint256 rand = random("TYP", _fantomonId, _sender) % 10000;

        if (       rand < 3200) {  // Aqua:   32%
            return 0;
        // 3200 + 320 = 3520
        } else if (rand < 3520) {  // Chaos:   3.2% (halved from 6.4%)
            return 1;
        // 3520 + 320 = 3840
        } else if (rand < 3840) {  // Cosmic:  3.2% (quartered from 12.8%)
            return 2;
        // 3840 + 960 = 4800
        } else if (rand < 4800) {  // Demon:   9.6%
            return 3;
        // 4800 + 480 = 5280
        } else if (rand < 5280) {  // Fairy:   4.8% (quartered from 19.2%)
            return 4;
        // 5280 + 2240 = 7520
        } else if (rand < 7520) {  // Gunk:   22.4%
            return 5;
        // 7520 + 160 = 7680
        } else if (rand < 7680) {  // Mineral: 1.6% (quartered from 6.4%)
            return 6;
        // 7680 + 1920 = 9600
        } else if (rand < 9600) {  // Plant:  19.2%
            return 7;
        // 9600 + 200 = 9800
        } else if (rand < 9800) {  // choose type based on trainer class boost: 2%
            return trainerClassTypeBoosts_[_trainerClass];
        // 9800 + 200 == 10000
        } else { //if (rand < 10000) {  // choose type based on trainer homeworld boost: 2%
            return trainerWorldTypeBoosts_[_trainerWorld];
        }
    }

    /* Classes are Relic or Ancient. Ancient is hyper-rare.
     * After choosing Type, choose Class. Some Types only have Relics,
     * in which case, just go with Relic.
     * Base probablity for rolling an Relic is 84% and Ancient is 4%
     *
     * Once a Type is rolled, a Class is rolled based on that Type.
     * Of course, if Type has no Ancients, then Relic is chosen.
     * If Type does have an Ancient, then Class is rolled as follows:
     * Base chances are: 84% Relic, 4% Ancient
     * The remaining 12% is allocated based on Trainer Class, Homeworld and Rarity.
     * Chances to roll an Ancient after rolling Aqua Type is divided by 5.
     * Chances to roll an Ancient after rolling Plant Type is divided by 3.
     * 
     * These tweaks for Aqua (Type=0) and Plant(Type=7) were implemented because
     * with so many Species in those Types, each Species is already allocated
     * a low percentage, so the 1 Ancient in that Type would end up with
     * similar roll % as the other Species of that Type.
     */
    function randClass(uint256 _fantomonId, uint8 _type, uint8 _trainerClass, uint8 _trainerWorld, uint8 _trainerRarity, address _sender) internal view returns (uint8) {
        if (numAncientsOfType[_type] == 0) {
            return 0;
        }

        uint256 rand = random("CLS", _fantomonId, _sender);

        if (_type == 0) {
            rand = rand % 50000;
            if (rand > 10000) {
                return 0;
            }
        //} else if (_type == 1 || _type == 3) {
        } else if (_type == 1) {
            rand = rand % 10000;
        //} else if (_type == 2 || _type == 4) {
        } else if (_type == 4) {
            rand = rand % 10000;
        } else if (_type == 6) {
            rand = rand % 10000;
        } else if (_type == 7) {
            rand = rand % 20000;
            if (rand > 10000) {
                return 0;
            }
        }

        // For class, homeworld and rarity, the rarer the attribute, the more likely to mint an Ancient

        // Base probablities
        if (rand <  8400) {  // Relic:  84%
            return 0;  // Relic
        } else if (rand <  8800) {  // Ancient: 4%
            return 1;  // Ancient

        // Probability boosts based on trainer class
        } else if (rand <  9200 && _trainerClass <  4) {   // Commons get no boost
            return 0;  // Relic
        } else if (rand <  8933 && _trainerClass <  8) {   // Boost from      rare  class: 1.33%
            return 1;  // Ancient
        } else if (rand <  9066 && _trainerClass < 12) {   // Boost from      epic  class: 2.66% (1.33 + 1.33)
            return 1;  // Ancient
        } else if (rand <  9200 && _trainerClass < 16) {   // Boost from legendary  class: 4%    (2.66 + 1.34)
            return 1;  // Ancient

        // Probability boosts based on trainer homeworld
        } else if (rand <  9600 && _trainerWorld <  4) {   // Commons get no boost
            return 0;  // Relic
        } else if (rand <  9333 && _trainerWorld <  8) {   // Boost from      rare  world: 1.33%
            return 1;  // Ancient
        } else if (rand <  9466 && _trainerWorld < 12) {   // Boost from      epic  world: 2.66% (1.33 + 1.33)
            return 1;  // Ancient
        } else if (rand <  9600 && _trainerWorld < 16) {   // Boost from legendary  world: 4%    (2.66 + 1.34)
            return 1;  // Ancient

        // Probability boosts based on trainer rarity
        } else if (rand <  9733 && _trainerRarity == 1) {  // Boost from      Rare rarity: 1.33%
            return 1;  // Ancient
        } else if (rand <  9866 && _trainerRarity == 2) {  // Boost from      Epic rarity: 2.66% (1.33 + 1.33)
            return 1;  // Ancient
        } else if (rand < 10000 && _trainerRarity == 3) {  // Boost from Legendary rarity: 4%    (2.66 + 1.34)
            return 1;  // Ancient

        } else {
            return 0;
        }
    }


    /* Choose one of the Species of the chosen Type.
     * If Ancient, only one option so choose it.
     */
    function randSpecies(uint256 _fantomonId, uint8 _type, uint8 _class, address _sender) internal view returns (uint8) {
        // Assumes that a _type and _class were chosen in a senseible way:
        //     ancient (class 1) should not be chosen for a _type that has no ancients (e.g. Chaos)
        uint256 rand;
        if (_class == 0) {  // Relic
            if (numRelicsOfType[_type] == 1) {
                return relicsOfType[_type][0];
            } else {
                rand = random("RLC", _fantomonId, _sender) % numRelicsOfType[_type];
                return relicsOfType[_type][rand];
            }
        } else { // _type == 1  // Ancient
            return ancientsOfType[_type][0];
        }
    }


    /* Choose a random attack based on a probability distribution.
     * This function is called twice to choose 2 attacks for a Fantomon.
     * On the second call, if the same attack is chosen again, retry.
     *
     * _idx: how many times this function has already been called for this fantomonId's mint
     * _attack0: if _idx > 0, this the 0th attack's index (to make sure one fantomon doesn't get assigned the same attack twice)
     */
    function randAttack(uint256 _fantomonId, address _sender, uint8 _idx, uint8 _attack0) internal view returns (uint8 attack) {
        uint256 rand = random("ATK", _fantomonId, _sender, _idx) % 100000;  // 12 attacks, 12 spAttacks
        if (rand < 50000) {  // regular attack
            // 30% tier: 10% each
            if (       rand < 10000) {
                attack = 0;
            } else if (rand < 20000) {
                attack = 1;
            } else if (rand < 30000) {
                attack = 2;
            // 15% tier:  5% each
            } else if (rand < 35000) {
                attack = 3;
            } else if (rand < 40000) {
                attack = 4;
            } else if (rand < 45000) {
                attack = 5;
            //  4% tier:  1.33% each
            } else if (rand < 46333) {
                attack = 6;
            } else if (rand < 47667) {
                attack = 7;
            } else if (rand < 49000) {
                attack = 8;
            //  1% tier:  0.33% each
            } else if (rand < 49333) {
                attack = 9;
            } else if (rand < 49667) {
                attack = 10;
            } else { // if (rand < 50000) {
                attack = 11;
            }
        } else {  // special attack
            // 30% tier: 10% each
            if (       rand < 60000) {
                attack = 12;
            } else if (rand < 70000) {
                attack = 13;
            } else if (rand < 80000) {
                attack = 14;
            // 15% tier:  5% each
            } else if (rand < 85000) {
                attack = 15;
            } else if (rand < 90000) {
                attack = 16;
            } else if (rand < 95000) {
                attack = 17;
            //  4% tier:  1.33% each
            } else if (rand < 96333) {
                attack = 18;
            } else if (rand < 97667) {
                attack = 19;
            } else if (rand < 99000) {
                attack = 20;
            //  1% tier:  0.33% each
            } else if (rand < 99333) {
                attack = 21;
            } else if (rand < 99667) {
                attack = 22;
            } else { // if (rand < 100000) {
                attack = 23;
            }
        }
        if (_idx > 0 && _attack0 == attack) {
            attack = randAttack(_fantomonId, _sender, _idx + 1, _attack0);
            if (_attack0 == attack) {
                if (attack == 0) {
                    attack = 1;
                } else {
                    attack = attack - 1;
                }
            }
        }
        // returns attack by default
    }

    /* Choose a random Mood and use Trainer Courage to boost probability of rarest/strongest Mood.
     * Mood is also used later when rolling all Variances.
     */
    function randMood(uint256 _fantomonId, uint256 _trainerCourage, address _sender) internal view returns (uint8) {
        // Chances of rarest mood increased by _trainerCourage/10
        uint256 courage = _trainerCourage > 100 ? 100 : _trainerCourage;
        uint256 rand = courage + (random("MOO", _fantomonId, _sender) % 1000);
        if (       rand < 350) {  // 35%
            return 0;
        } else if (rand < 625) {  // 27.5%
            return 1;
        } else if (rand < 825) {  // 20%
            return 2;
        } else if (rand < 950) {  // 12.5%
            return 3;
        } else {  // if (rand < 1000) {  //  5%
            return 4;
        }
    }


    /* Choose a random Essence and use Trainer Healing to boost probability of rarest/strongest Essence.
     * Essence is a stat-modifier used when scaling/calculating ALL stats.
     */
    function randEssence(uint256 _fantomonId, uint256 _trainerHealing, address _sender) internal view returns (uint8) {
        // Chances of rarest essence increased by _trainerHealing/10
        uint256 healing = _trainerHealing > 100 ? 100 : _trainerHealing;
        uint256 rand = healing + (random("ESS", _fantomonId, _sender) % 1000);
        // 40% tier: 20% each
        if (       rand < 200) {  // 20%
            return 0;
        } else if (rand < 400) {  // 20%
            return 1;
        // 48% tier:  7% each
        } else if (rand < 470) {  //  7%
            return 2;
        } else if (rand < 540) {  //  7%
            return 3;
        } else if (rand < 610) {  //  7%
            return 4;
        } else if (rand < 680) {  //  7%
            return 5;
        } else if (rand < 750) {  //  7%
            return 6;
        } else if (rand < 820) {  //  7%
            return 7;
        } else if (rand < 890) {  //  7%
            return 8;
        // 11% tier:  2.2% each
        } else if (rand < 912) {  // 2.2%
            return 9;
        } else if (rand < 934) {  // 2.2%
            return 10;
        } else if (rand < 956) {  // 2.2%
            return 11;
        } else if (rand < 978) {  // 2.2%
            return 12;
        } else {  // if (rand < 1000) {  // 2.2%
            return 13;
        }
    }

    /* Stat modifier that is generated for each of the 5 stats
     * Fantomon Class affects the MSD (most significant digit)
     * Fantomon Mood affects the LSD (least significant digit)
     */
    function randVariance(uint256 _fantomonId, uint8 _class, uint8 _mood, address _sender, uint8 _idx) internal view returns (uint8) {
        // choose rand MSD based on class (multiplied by 10: 0, 10 or 20)
        // choose rand LSD based on mood and add to MSD
        uint8 msd;  // Most significant digit - based on class
        uint256 rand = random("VAR", _fantomonId, _sender, _idx);
        if (_class == 0) {  // Relic
            if (rand >> 255 == 0) {  // choose 0 or 1 at random
                msd = 0;
            } else {  // == 1
                msd = 10;
            }
        } else {  // if (class == 1) {  // Ancient
            if (rand >> 255 == 1) { // choose 0 or 1 at random
                msd = 10;
            } else {  // == 1
                msd = 20;
            }
        }
        // Least significant digit - based on mood (random num from 0-5 + mood)
        // Mood ranges from 0-4, so teh LSD is ranging from 0-9
        return msd + uint8(rand % 6) + _mood;
    }

    /* Used at mint to generate a random Starter Fantomon and initialize its stats and attributes
     */
    function randStarter(uint256 _tokenId, address _sender,
                         uint256 _courage, uint256 _healing, uint8 _choice) external view override returns (FantomonLib.Fmon memory _fmon) {
            uint8 typ;
            uint8 class = 0;
            uint8 species;
            if (_choice == 0) {
                typ = 0;
                species = 40;
            } else {  // if (_choice == 1) {
                typ = 1;
                species = 41;
            }

            _fmon.lvl = 1;
            // Morph, xp, dmg, nutrients and mastery remain unset and auto-init to 0
            //_fmon.morph = 0;
            //_fmon.xp    = 0;
            //_fmon.dmg   = 0;
            //_fmon.nutrients = Stats(0, 0, 0, 0, 0);  // , 0);
            //_fmon.mastery   = Stats(0, 0, 0, 0, 0);  // , 0);

            _fmon.attrs.typ     = typ;
            _fmon.attrs.class   = class;
            _fmon.attrs.species = species;
            _fmon.attrs.mood    = randMood(_tokenId, _courage, _sender);
            _fmon.attrs.essence = randEssence(_tokenId, _healing, _sender);

            _fmon.modifiers.essence           = ESSENCE_VALUES[_fmon.attrs.essence];
            _fmon.modifiers.hpVariance        = randVariance(_tokenId, class, _fmon.attrs.mood, _sender, 0);
            _fmon.modifiers.attackVariance    = randVariance(_tokenId, class, _fmon.attrs.mood, _sender, 1);
            _fmon.modifiers.defenseVariance   = randVariance(_tokenId, class, _fmon.attrs.mood, _sender, 2);
            _fmon.modifiers.spAttackVariance  = randVariance(_tokenId, class, _fmon.attrs.mood, _sender, 3);
            _fmon.modifiers.spDefenseVariance = randVariance(_tokenId, class, _fmon.attrs.mood, _sender, 4);

            _fmon.attacks.attack0 = randAttack(_tokenId, _sender, 0, 0);
            _fmon.attacks.attack1 = randAttack(_tokenId, _sender, 1, _fmon.attacks.attack0);

            _fmon.base = BASE_SPECIES_STATS[species];
    }

    /* Used at mint to generate a random Fantomon and initialize its stats and attributes
     */
    function randFmon(uint256 _tokenId, address _sender,
                          uint8 _class, uint8 _homeworld,
                          uint8 _rarity, uint256 _courage, uint256 _healing) external view override returns (FantomonLib.Fmon memory _fmon) {

            _fmon.lvl = 1;
            // Morph, xp, dmg, nutrients and mastery remain unset and auto-init to 0
            //_fmon.morph = 0;
            //_fmon.xp    = 0;
            //_fmon.dmg   = 0;
            //_fmon.nutrients = Stats(0, 0, 0, 0, 0);  // , 0);
            //_fmon.mastery   = Stats(0, 0, 0, 0, 0);  // , 0);

            _fmon.attrs.typ     = randType(_tokenId, _class, _homeworld, _sender);
            _fmon.attrs.class   = randClass(_tokenId, _fmon.attrs.typ, _class, _homeworld, _rarity, _sender);
            _fmon.attrs.species = randSpecies(_tokenId, _fmon.attrs.typ, _fmon.attrs.class, _sender);
            _fmon.attrs.mood    = randMood(_tokenId, _courage, _sender);
            _fmon.attrs.essence = randEssence(_tokenId, _healing, _sender);

            _fmon.modifiers.essence           = ESSENCE_VALUES[_fmon.attrs.essence];
            _fmon.modifiers.hpVariance        = randVariance(_tokenId, _fmon.attrs.class, _fmon.attrs.mood, _sender, 0);
            _fmon.modifiers.attackVariance    = randVariance(_tokenId, _fmon.attrs.class, _fmon.attrs.mood, _sender, 1);
            _fmon.modifiers.defenseVariance   = randVariance(_tokenId, _fmon.attrs.class, _fmon.attrs.mood, _sender, 2);
            _fmon.modifiers.spAttackVariance  = randVariance(_tokenId, _fmon.attrs.class, _fmon.attrs.mood, _sender, 3);
            _fmon.modifiers.spDefenseVariance = randVariance(_tokenId, _fmon.attrs.class, _fmon.attrs.mood, _sender, 4);

            _fmon.attacks.attack0 = randAttack(_tokenId, _sender, 0, 0);
            _fmon.attacks.attack1 = randAttack(_tokenId, _sender, 1, _fmon.attacks.attack0);

            _fmon.base = BASE_SPECIES_STATS[_fmon.attrs.species];
    }

    /**************************************************************************
     * Helper functions
     **************************************************************************/
    function random(string memory _tag, uint256 _int0, address _sender) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_tag, _int0, block.coinbase, blockhash(block.number-1), block.timestamp, _sender)));
    }
    function random(string memory _tag, uint256 _int0, address _sender, uint8 _idx) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_tag, _int0, block.coinbase, blockhash(block.number-1), block.timestamp, _sender, _idx)));
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
}
