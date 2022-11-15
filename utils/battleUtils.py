"""Utilitiess for processing Fantomon battle results
"""
import json
import math
import numpy as np
import matplotlib.pyplot as plt


NUM_LVLS = 4
NUM_SPECIES = 40  # 42

SPECIES = [
    # AQUA
    "Exotius",
    "Waroda",
    "Flamphy",
    "Buui",
    "Jilius",
    "Octmii",
    "Starfy",
    "Luupe",
    "Milius",
    "Shelfy",  # Ancient
    #"MorphedShelfy",  # Ancient

    # CHAOS
    "Ephisto",
    "Kazaaba", # Ancient
    #"MorphedKazaaba", # Ancient

    # COSMIC
    "Xatius",
    "Tapoc",
    "Slusa",
    "Cosmii",

    # DEMON
    "Decro",
    "Merich",
    "Zeepuu",

    # FAIRY
    "Huffly",
    "Munsa",
    "Fenii",
    "Fleppa",
    "Mii",
    "Jixpi",  # Ancient
    #"MorphedJixpi",  # Ancient

    # GUNK
    "Kaibu",
    "Koob",
    "Woobek",
    "Googa",
    "Piniju",
    "Gubba",
    "Belkezor",

    # MINERAL
    "Meph",
    "Relixia",  # Ancient
    #"MorphedRelixia",  # Ancient

    # PLANT
    "Shrooto",
    "Sphin",
    "Rooto",
    "Icaray",
    "Brutu",
    "Grongel",  # Ancient
    #"MorphedGrongel"  # Ancient

    # Starter
    "Larik",  # Aqua
    "Gretto"  # Chaos
]

STATS = [
    [40000000 , 30000000 , 25000000 , 50000000 , 32000000], # 40000000);  # Exotius            Total: 147000000
    [46000000 , 45000000 , 32000000 , 50000000 , 40000000], # 45000000);  # Waroda             Total: 183000000
    [10000000 , 35000000 , 15000000 , 35000000 , 20000000], # 15000000);  # Flamphy            Total:  85000000
    [50000000 , 45000000 , 40000000 , 55000000 , 40000000], # 38000000);  # Buui               Total: 200000000
    [24000000 , 32000000 , 12000000 , 54000000 , 30000000], # 35000000);  # Jilius             Total: 122000000
    [20000000 , 25000000 , 25000000 , 45000000 , 20000000], # 35000000);  # Octmii             Total: 105000000
    [25000000 , 32000000 , 20000000 , 45000000 , 28000000], # 10000000);  # Starfy             Total: 120000000
    [50000000 , 35000000 , 13000000 , 33000000 , 13000000], # 15000000);  # Luupe              Total: 114000000
    [30000000 , 38000000 , 38000000 , 48000000 , 25000000], # 25000000);  # Milius             Total: 149000000
    [50000000 , 42000000 , 22000000 , 45000000 , 30000000], # 35000000);  # Shelfy  # Ancient  Total: 159000000
    [38000000 , 29000000 , 28000000 , 45000000 , 29000000], # 26000000);  # Ephisto            Total: 139000000
    [50000000 , 42000000 , 22000000 , 45000000 , 30000000], # 35000000);  # Kazaaba # Ancient  Total: 159000000
    [40000000 , 35000000 , 20000000 , 55000000 , 35000000], # 35000000);  # Xatius             Total: 155000000
    [28000000 , 40000000 , 18000000 , 54000000 , 29000000], # 24000000);  # Tapoc              Total: 139000000
    [15000000 , 32000000 , 21000000 , 48000000 , 22000000], # 20000000);  # Slusa              Total: 108000000
    [40000000 , 49000000 , 18000000 , 55000000 , 19000000], # 40000000);  # Cosmii             Total: 151000000
    [32000000 , 28000000 , 28000000 , 44000000 , 24000000], # 10000000);  # Decro              Total: 126000000
    [35000000 , 32000000 , 30000000 , 40000000 , 25000000], # 25000000);  # Merich             Total: 132000000
    [38000000 , 40000000 , 15000000 , 52000000 , 22000000], # 20000000);  # Zeepuu             Total: 137000000
    [30000000 , 38000000 , 20000000 , 42000000 , 20000000], # 25000000);  # Huffly             Total: 120000000
    [32000000 , 36000000 , 30000000 , 38000000 , 32000000], # 15000000);  # Munsa              Total: 138000000
    [26000000 , 34000000 , 20000000 , 42000000 , 20000000], # 20000000);  # Fenii              Total: 112000000
    [20000000 , 40000000 , 18000000 , 42000000 , 25000000], # 15000000);  # Fleppa             Total: 115000000
    [48000000 , 40000000 , 15000000 , 48000000 , 35000000], # 45000000);  # Mii                Total: 156000000
    [50000000 , 35000000 , 45000000 , 50000000 , 42000000], # 43000000);  # Jixpi   # Ancient  Total: 192000000
    [38000000 , 30000000 , 30000000 , 30000000 , 15000000], # 25000000);  # Kaibu              Total: 113000000
    [23000000 , 30000000 , 25000000 , 45000000 , 20000000], # 35000000);  # Koob               Total: 113000000
    [25000000 , 25000000 , 15000000 , 55000000 , 30000000], # 15000000);  # Woobek             Total: 120000000
    [20000000 , 25000000 , 25000000 , 55000000 , 30000000], # 15000000);  # Googa              Total: 125000000
    [20000000 , 35000000 , 15000000 , 55000000 , 30000000], # 25000000);  # Piniju             Total: 125000000
    [10000000 , 32000000 , 14000000 , 40000000 , 10000000], #  5000000);  # Gubba              Total:  76000000
    [25000000 , 42000000 , 28000000 , 39000000 , 25000000], # 14000000);  # Belkezor           Total: 129000000
    [25000000 , 32000000 , 24000000 , 50000000 , 24000000], # 20000000);  # Meph               Total: 125000000
    [50000000 , 22000000 , 38000000 , 45000000 , 45000000], # 12000000);  # Relixia # Ancient  Total: 170000000
    [26000000 , 37000000 , 29000000 , 40000000 , 30000000], # 15000000);  # Shrooto            Total: 132000000
    [39000000 , 38000000 , 25000000 , 45000000 , 23000000], # 25000000);  # Sphin              Total: 140000000
    [32000000 , 33000000 , 25000000 , 44000000 , 24000000], # 22000000);  # Rooto              Total: 128000000
    [28000000 , 40000000 , 18000000 , 54000000 , 29000000], # 24000000);  # Icaray             Total: 139000000
    [35000000 , 40000000 , 18000000 , 49000000 , 25000000], # 18000000);  # Brutu              Total: 137000000
    [30000000 , 35000000 , 30000000 , 40000000 , 15000000]#, # 25000000);  # Grongel # Ancient  Total: 120000000
    #[35000000 , 40000000 , 20000000 , 50000000 , 20000000], # 25000000);  # Larik   # Starter  Total: 135000000
    #[35000000 , 30000000 , 30000000 , 40000000 , 30000000]  # 25000000);  # Gretto  # Starter  Total: 135000000
]
STAT_SUMS = [sum(s for s in stat)      for stat in STATS]
ATK_SUMS  = [sum(s for s in [stat[1], stat[3]]) for stat in STATS]
DEF_SUMS  = [sum(s for s in [stat[2], stat[4]]) for stat in STATS]

REG_SUMS    = [sum(s for s in [stat[1], stat[2]])          for stat in STATS]
SP_SUMS     = [sum(s for s in [stat[3], stat[4]])          for stat in STATS]
HP_REG_SUMS = [sum(s for s in [stat[0], stat[1], stat[2]]) for stat in STATS]
HP_SP_SUMS  = [sum(s for s in [stat[0], stat[3], stat[4]]) for stat in STATS]

HPS     = [stat[0] for stat in STATS]
ATKS    = [stat[1] for stat in STATS]
DEFS    = [stat[2] for stat in STATS]
SP_ATKS = [stat[3] for stat in STATS]
SP_DEFS = [stat[4] for stat in STATS]

with open('gen/pvp-data.json', 'r') as data_json:
    matchups = json.load(data_json)

aliceMonTypes   = [elem['aliceMon']['typ']          for elem in matchups]
aliceMonSpecies = [elem['aliceMon']['species']      for elem in matchups]
aliceMonAttack0 = [elem['aliceMon']['attack0']      for elem in matchups]
#aliceMonAttack1 = [elem['aliceMon']['attack1']      for elem in matchups]
aliceMonMood    = [elem['aliceMon']['mood']         for elem in matchups]
aliceMonEssence = [elem['aliceMon']['essence']      for elem in matchups]
aliceMonV0      = [elem['aliceMon']['variances'][0] for elem in matchups]
aliceMonV1      = [elem['aliceMon']['variances'][1] for elem in matchups]
aliceMonV2      = [elem['aliceMon']['variances'][2] for elem in matchups]
aliceMonV3      = [elem['aliceMon']['variances'][3] for elem in matchups]
aliceMonV4      = [elem['aliceMon']['variances'][4] for elem in matchups]

bobbyMonTypes   = [elem['bobbyMon']['typ']          for elem in matchups]
bobbyMonSpecies = [elem['bobbyMon']['species']      for elem in matchups]
bobbyMonAttack0 = [elem['bobbyMon']['attack0']      for elem in matchups]
#bobbyMonAttack1 = [elem['bobbyMon']['attack1']      for elem in matchups]
bobbyMonMood    = [elem['bobbyMon']['mood']         for elem in matchups]
bobbyMonEssence = [elem['bobbyMon']['essence']      for elem in matchups]
bobbyMonV0      = [elem['bobbyMon']['variances'][0] for elem in matchups]
bobbyMonV1      = [elem['bobbyMon']['variances'][1] for elem in matchups]
bobbyMonV2      = [elem['bobbyMon']['variances'][2] for elem in matchups]
bobbyMonV3      = [elem['bobbyMon']['variances'][3] for elem in matchups]
bobbyMonV4      = [elem['bobbyMon']['variances'][4] for elem in matchups]


aliceMatchesPerSpecies = [[match for match in matchups if match['aliceMon']['species'] == species] for species in range(0, NUM_SPECIES)]
bobbyMatchesPerSpecies = [[match for match in matchups if match['bobbyMon']['species'] == species] for species in range(0, NUM_SPECIES)]

#aliceWinsPerSpecies = [sum(1 for match in matchups if match['aliceMon']['species'] == species) for species in range(0, NUM_SPECIES)]
#bobbyWinsPerSpecies = [sum(1 for match in matchups if match['bobbyMon']['species'] == species) for species in range(0, NUM_SPECIES)]

aliceResultsPerSpecies = [[result for match in aliceMatchesPerSpecies[species] for result in match['winners']] for species in range(0, NUM_SPECIES)]
bobbyResultsPerSpecies = [[result for match in bobbyMatchesPerSpecies[species] for result in match['winners']] for species in range(0, NUM_SPECIES)]

aliceBattlesPerSpecies = [len(aliceResultsPerSpecies[species]) for species in range(0, NUM_SPECIES)]
aliceWinsPerSpecies    = [sum(1 for result in aliceResultsPerSpecies[species] if result ==  0) for species in range(0, NUM_SPECIES)]
aliceLossesPerSpecies  = [sum(1 for result in aliceResultsPerSpecies[species] if result ==  1) for species in range(0, NUM_SPECIES)]
aliceTiesPerSpecies    = [sum(1 for result in aliceResultsPerSpecies[species] if result == -1) for species in range(0, NUM_SPECIES)]


aliceWinRatePerSpecies = [float(aliceWinsPerSpecies[species])/aliceBattlesPerSpecies[species] if aliceBattlesPerSpecies[species] else 0 for species in range(0, NUM_SPECIES)]
aliceLossRatePerSpecies = [float(aliceLossesPerSpecies[species])/aliceBattlesPerSpecies[species] if aliceBattlesPerSpecies[species] else 0 for species in range(0, NUM_SPECIES)]

# rate of certain type, rate of certain species

bobbyBattlesPerSpecies = [len(bobbyResultsPerSpecies[species]) for species in range(0, NUM_SPECIES)]
bobbyWinsPerSpecies    = [sum(1 for result in bobbyResultsPerSpecies[species] if result ==  1) for species in range(0, NUM_SPECIES)]
bobbyLossesPerSpecies  = [sum(1 for result in bobbyResultsPerSpecies[species] if result ==  0) for species in range(0, NUM_SPECIES)]
bobbyTiesPerSpecies    = [sum(1 for result in bobbyResultsPerSpecies[species] if result == -1) for species in range(0, NUM_SPECIES)]

bobbyWinRatePerSpecies = [float(bobbyWinsPerSpecies[species])/bobbyBattlesPerSpecies[species] if bobbyBattlesPerSpecies[species] else 0 for species in range(0, NUM_SPECIES)]
bobbyLossRatePerSpecies = [float(bobbyLossesPerSpecies[species])/bobbyBattlesPerSpecies[species] if bobbyBattlesPerSpecies[species] else 0 for species in range(0, NUM_SPECIES)]

####
alicePerLevelResultsPerSpecies   = [[[match['winners'][i] for match in aliceMatchesPerSpecies[species]] for species in range(0, NUM_SPECIES)] for i in range(0, NUM_LVLS)]

alicePerLevelBattlesPerSpecies   = [[len(alicePerLevelResultsPerSpecies[i][species])   for species in range(0, NUM_SPECIES)] for i in range (0, NUM_LVLS)]
alicePerLevelWinsPerSpecies   = [[sum(1 for result in alicePerLevelResultsPerSpecies[i][species]   if result ==  0) for species in range(0, NUM_SPECIES)] for i in range(0, NUM_LVLS)]
alicePerLevelLossesPerSpecies = [[sum(1 for result in alicePerLevelResultsPerSpecies[i][species]   if result ==  1) for species in range(0, NUM_SPECIES)] for i in range(0, NUM_LVLS)]
alicePerLevelTiesPerSpecies   = [[sum(1 for result in alicePerLevelResultsPerSpecies[i][species]   if result == -1) for species in range(0, NUM_SPECIES)] for i in range(0, NUM_LVLS)]

alicePerLevelWinRatePerSpecies   = [[float(alicePerLevelWinsPerSpecies[i][species])  /alicePerLevelBattlesPerSpecies[i][species]   if alicePerLevelBattlesPerSpecies[i][species]   else 0 for species in range(0, NUM_SPECIES)] for i in range(0, NUM_LVLS)]


bobbyPerLevelResultsPerSpecies   = [[[match['winners'][i] for match in bobbyMatchesPerSpecies[species]] for species in range(0, NUM_SPECIES)] for i in range(0, NUM_LVLS)]

bobbyPerLevelBattlesPerSpecies   = [[len(bobbyPerLevelResultsPerSpecies[i][species])   for species in range(0, NUM_SPECIES)] for i in range (0, NUM_LVLS)]
bobbyPerLevelWinsPerSpecies   = [[sum(1 for result in bobbyPerLevelResultsPerSpecies[i][species]   if result ==  1) for species in range(0, NUM_SPECIES)] for i in range(0, NUM_LVLS)]
bobbyPerLevelLossesPerSpecies = [[sum(1 for result in bobbyPerLevelResultsPerSpecies[i][species]   if result ==  0) for species in range(0, NUM_SPECIES)] for i in range(0, NUM_LVLS)]
bobbyPerLevelTiesPerSpecies   = [[sum(1 for result in bobbyPerLevelResultsPerSpecies[i][species]   if result == -1) for species in range(0, NUM_SPECIES)] for i in range(0, NUM_LVLS)]

bobbyPerLevelWinRatePerSpecies   = [[float(bobbyPerLevelWinsPerSpecies[i][species])  /bobbyPerLevelBattlesPerSpecies[i][species]   if bobbyPerLevelBattlesPerSpecies[i][species]   else 0 for species in range(0, NUM_SPECIES)] for i in range(0, NUM_LVLS)]




###########
#aliceL1ResultsPerSpecies   = [[match['winners'][0] for match in aliceMatchesPerSpecies[species]] for species in range(0, NUM_SPECIES)]
#aliceL100ResultsPerSpecies = [[match['winners'][3] for match in aliceMatchesPerSpecies[species]] for species in range(0, NUM_SPECIES)]
#
#aliceL1BattlesPerSpecies   = [len(aliceL1ResultsPerSpecies[species])   for species in range(0, NUM_SPECIES)]
#aliceL100BattlesPerSpecies = [len(aliceL100ResultsPerSpecies[species]) for species in range(0, NUM_SPECIES)]
#
#aliceL1WinsPerSpecies   = [sum(1 for result in aliceL1ResultsPerSpecies[species]   if result ==  0) for species in range(0, NUM_SPECIES)]
#aliceL100WinsPerSpecies = [sum(1 for result in aliceL100ResultsPerSpecies[species] if result ==  0) for species in range(0, NUM_SPECIES)]
#
#aliceL1WinRatePerSpecies   = [float(aliceL1WinsPerSpecies[species])  /aliceL1BattlesPerSpecies[species]   if aliceL1BattlesPerSpecies[species]   else 0 for species in range(0, NUM_SPECIES)]
#aliceL100WinRatePerSpecies = [float(aliceL100WinsPerSpecies[species])/aliceL100BattlesPerSpecies[species] if aliceL100BattlesPerSpecies[species] else 0 for species in range(0, NUM_SPECIES)]
#
#
#bobbyL1ResultsPerSpecies   = [[match['winners'][0] for match in bobbyMatchesPerSpecies[species]] for species in range(0, NUM_SPECIES)]
#bobbyL100ResultsPerSpecies = [[match['winners'][3] for match in bobbyMatchesPerSpecies[species]] for species in range(0, NUM_SPECIES)]
#
#bobbyL1BattlesPerSpecies   = [len(bobbyL1ResultsPerSpecies[species])   for species in range(0, NUM_SPECIES)]
#bobbyL100BattlesPerSpecies = [len(bobbyL100ResultsPerSpecies[species]) for species in range(0, NUM_SPECIES)]
#
#bobbyL1WinsPerSpecies   = [sum(1 for result in bobbyL1ResultsPerSpecies[species]   if result ==  0) for species in range(0, NUM_SPECIES)]
#bobbyL100WinsPerSpecies = [sum(1 for result in bobbyL100ResultsPerSpecies[species] if result ==  0) for species in range(0, NUM_SPECIES)]
#
#bobbyL1WinRatePerSpecies   = [float(bobbyL1WinsPerSpecies[species])  /bobbyL1BattlesPerSpecies[species]   if bobbyL1BattlesPerSpecies[species]   else 0 for species in range(0, NUM_SPECIES)]
#bobbyL100WinRatePerSpecies = [float(bobbyL100WinsPerSpecies[species])/bobbyL100BattlesPerSpecies[species] if bobbyL100BattlesPerSpecies[species] else 0 for species in range(0, NUM_SPECIES)]
#####

totalWinsPerSpecies    = [aliceWinsPerSpecies[species]+bobbyWinsPerSpecies[species] for species in range(0, NUM_SPECIES)]
totalBattlesPerSpecies = [aliceBattlesPerSpecies[species]+bobbyBattlesPerSpecies[species] for species in range(0, NUM_SPECIES)]

totalWinRatePerSpecies = [float(totalWinsPerSpecies[species])/totalBattlesPerSpecies[species] if totalBattlesPerSpecies[species] else 0 for species in range(0, NUM_SPECIES)]


totalPerLevelWinsPerSpecies   = [[alicePerLevelWinsPerSpecies[i][species]+bobbyPerLevelWinsPerSpecies[i][species] for species in range(0, NUM_SPECIES)] for i in range(0, NUM_LVLS)]
totalPerLevelLossesPerSpecies = [[alicePerLevelLossesPerSpecies[i][species]+bobbyPerLevelLossesPerSpecies[i][species] for species in range(0, NUM_SPECIES)] for i in range(0, NUM_LVLS)]
totalPerLevelTiesPerSpecies   = [[alicePerLevelTiesPerSpecies[i][species]+bobbyPerLevelTiesPerSpecies[i][species] for species in range(0, NUM_SPECIES)] for i in range(0, NUM_LVLS)]
totalPerLevelBattlesPerSpecies = [[alicePerLevelBattlesPerSpecies[i][species]+bobbyPerLevelBattlesPerSpecies[i][species] for species in range(0, NUM_SPECIES)] for i in range(0, NUM_LVLS)]

totalPerLevelWinRatePerSpecies = [[float(totalPerLevelWinsPerSpecies[i][species])/totalPerLevelBattlesPerSpecies[i][species] if totalPerLevelBattlesPerSpecies[i][species] else 0 for species in range(0, NUM_SPECIES)] for i in range(0, NUM_LVLS)]


speciesSortedByWins = np.argsort(totalWinRatePerSpecies)

perLevelSpeciesSortedByWins = [np.argsort(totalPerLevelWinRatePerSpecies[i]) for i in range(0, NUM_LVLS)]

statsSortedByWins = {
    'STATS'         : np.array(STATS      )[speciesSortedByWins],
    'STAT_SUM'      : np.array(STAT_SUMS  )[speciesSortedByWins],
    'ATK_SUM'       : np.array(ATK_SUMS   )[speciesSortedByWins],
    'DEF_SUM'       : np.array(DEF_SUMS   )[speciesSortedByWins],
    'REG_SUMS'      : np.array(REG_SUMS   )[speciesSortedByWins],
    'SP_SUMS'       : np.array(SP_SUMS    )[speciesSortedByWins],
    'HP_REG_SUMS'   : np.array(HP_REG_SUMS)[speciesSortedByWins],
    'HP_SP_SUMS'    : np.array(HP_SP_SUMS )[speciesSortedByWins],
    'HP'            : np.array(HPS        )[speciesSortedByWins],
    'ATK'           : np.array(ATKS       )[speciesSortedByWins],
    'DEF'           : np.array(DEFS       )[speciesSortedByWins],
    'SP_ATK'        : np.array(SP_ATKS    )[speciesSortedByWins],
    'SP_DEF'        : np.array(SP_DEFS    )[speciesSortedByWins],
}

for i in range(0, NUM_LVLS):
    statsSortedByWins[f'l{i}_STATS'      ] = np.array(STATS      )[perLevelSpeciesSortedByWins[i]]
    statsSortedByWins[f'l{i}_STAT_SUM'   ] = np.array(STAT_SUMS  )[perLevelSpeciesSortedByWins[i]]
    statsSortedByWins[f'l{i}_ATK_SUM'    ] = np.array(ATK_SUMS   )[perLevelSpeciesSortedByWins[i]]
    statsSortedByWins[f'l{i}_DEF_SUM'    ] = np.array(DEF_SUMS   )[perLevelSpeciesSortedByWins[i]]
    statsSortedByWins[f'l{i}_REG_SUMS'   ] = np.array(REG_SUMS   )[perLevelSpeciesSortedByWins[i]]
    statsSortedByWins[f'l{i}_SP_SUMS'    ] = np.array(SP_SUMS    )[perLevelSpeciesSortedByWins[i]]
    statsSortedByWins[f'l{i}_HP_REG_SUMS'] = np.array(HP_REG_SUMS)[perLevelSpeciesSortedByWins[i]]
    statsSortedByWins[f'l{i}_HP_SP_SUMS' ] = np.array(HP_SP_SUMS )[perLevelSpeciesSortedByWins[i]]
    statsSortedByWins[f'l{i}_HP'         ] = np.array(HPS        )[perLevelSpeciesSortedByWins[i]]
    statsSortedByWins[f'l{i}_ATK'        ] = np.array(ATKS       )[perLevelSpeciesSortedByWins[i]]
    statsSortedByWins[f'l{i}_DEF'        ] = np.array(DEFS       )[perLevelSpeciesSortedByWins[i]]
    statsSortedByWins[f'l{i}_SP_ATK'     ] = np.array(SP_ATKS    )[perLevelSpeciesSortedByWins[i]]
    statsSortedByWins[f'l{i}_SP_DEF'     ] = np.array(SP_DEFS    )[perLevelSpeciesSortedByWins[i]]

fig = plt.figure()
fig.suptitle('Stat effects on winrate: on each chart, left is least wins, right is most')

LEVELS = ['ALL', 1, 10, 50, 100]  # row side titles (left / ylabels)

subplot_idx = 1
subplot_y = NUM_LVLS + 1
subplot_x = math.ceil(float(len(statsSortedByWins.keys())) / subplot_y)
for k, v in statsSortedByWins.items():
    plt.subplot(subplot_y, subplot_x, subplot_idx)
    plt.plot(v)
    print(f'{k} last val: {v[-1]}')
    #if subplot_idx <= subplot_x:
    plt.title(k)
    if subplot_idx % subplot_x == 1:
        plt.ylabel(f'LVL: {LEVELS[int(((subplot_idx-1))/subplot_x)]}')

    print(f'${k}\tORDERED: {v}')
    subplot_idx += 1

plt.show()

# need to accumulate info per type, not per tokenId

#subx = 6
#suby = 3
#
#fig = plt.figure()
#tokenId = trainer[0]
#kinship = trainer[1]
#flare   = trainer[2]
#healing = trainer[3]
#courage = trainer[4]
#wins    = trainer[5]
#losses  = trainer[6]
#rarity  = trainer[7]
#cls     = trainer[8]
#face    = trainer[9]
#world   = trainer[10]
#
#fig.suptitle(f'Trainer ({tokenId}) - Kinship: {kinship}, Flare: {flare}, Healing {healing}, Courage {courage}, Wins: {wins}, Losses: {losses}, Rarity: {rarity}, Class: {cls}, Face: {face}, World: {world}')
#
#def hist(attrIdx, label, num_bins, subplot_idx):
#    # attrIdx must start at 1
#    plt.subplot(suby, subx, subplot_idx)
#    attr_col = attrs[:, attrIdx]
#    bins = np.arange(0, num_bins + 1) - 0.5
#    ticks = np.arange(0, num_bins)
#    plt.hist(attr_col, bins=bins, ec="k")
#    if num_bins <= 14:
#        plt.xticks(ticks)
#    else:
#        plt.xticks(ticks, rotation=90, fontsize='xx-small')
#    plt.title(label)
#
#hist(1  , "types"     , 8  , 1)
#hist(2  , "classes"   , 2  , 2)
#hist(3  , "species"   , 40 , 3)
#hist(4  , "attack0"   , 24 , 7)
#hist(5  , "attack1"   , 24 , 8)
#hist(6  , "moods"     , 5  , 9)
#hist(7  , "essences"  , 14 , 10)
#hist(8  , "variance0" , 30 , 13)
#hist(9  , "variance1" , 30 , 14)
#hist(10 , "variance2" , 30 , 15)
#hist(11 , "variance3" , 30 , 16)
#hist(12 , "variance4" , 30 , 17)
#hist(13 , "variance5" , 30 , 18)
#
#plt.show()
