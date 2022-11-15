"""Utilitiess for processing Fantomon attributes
"""
import json
import numpy as np
import matplotlib.pyplot as plt


with open('gen/fantomonAttributes0.json', 'r') as attrs_json:
    fmon_data = json.load(attrs_json)
    trainer = fmon_data['trainer']
    attrs   = np.array(fmon_data['fmons'])


subx = 5
suby = 3

fig = plt.figure()
tokenId = trainer[0]
kinship = trainer[1]
flare   = trainer[2]
healing = trainer[3]
courage = trainer[4]
wins    = trainer[5]
losses  = trainer[6]
rarity  = trainer[7]
cls     = trainer[8]
face    = trainer[9]
world   = trainer[10]

fig.suptitle(f'Trainer ({tokenId}) - Kinship: {kinship}, Flare: {flare}, Healing {healing}, Courage {courage}, Wins: {wins}, Losses: {losses}, Rarity: {rarity}, Class: {cls}, Face: {face}, World: {world}')

def hist(label, attrList, num_bins, subplot_idx):
    plt.subplot(suby, subx, subplot_idx)
    bins = np.arange(0, num_bins + 1) - 0.5
    ticks = np.arange(0, num_bins)
    plt.hist(attrList, bins=bins, ec="k")
    if num_bins <= 14:
        plt.xticks(ticks)
    else:
        plt.xticks(ticks, rotation=90, fontsize='xx-small')
    plt.title(label)

"""
attributes:
class   7:0
typ     7:1
species 7:2
mood    7:3
essence 7:4

modifiers:
hpVariance 8:1
attackVariance 8:2
defenseVariance 8:3
spAttackVariance 8:4
spDefenseVariance 8:5

attacks:
attack0 9:0
attack1 9:1
"""

cls               = [fmon[7][0] for fmon in fmon_data['fmons']]
typ               = [fmon[7][1] for fmon in fmon_data['fmons']]
species           = [fmon[7][2] for fmon in fmon_data['fmons']]
mood              = [fmon[7][3] for fmon in fmon_data['fmons']]
essence           = [fmon[7][4] for fmon in fmon_data['fmons']]
hpVariance        = [fmon[8][1] for fmon in fmon_data['fmons']]
attackVariance    = [fmon[8][2] for fmon in fmon_data['fmons']]
defenseVariance   = [fmon[8][3] for fmon in fmon_data['fmons']]
spAttackVariance  = [fmon[8][4] for fmon in fmon_data['fmons']]
spDefenseVariance = [fmon[8][5] for fmon in fmon_data['fmons']]
attack0           = [fmon[9][0] for fmon in fmon_data['fmons']]
attack1           = [fmon[9][1] for fmon in fmon_data['fmons']]


hist("classes"           , cls               ,  2 ,  1)
hist("types"             , typ               ,  8 ,  2)
hist("species"           , species           , 42 ,  3)
hist("moods"             , mood              ,  5 ,  4)
hist("essences"          , essence           , 14 ,  5)
hist("hpVariance"        , hpVariance        , 30 ,  6)
hist("attackVariance"    , attackVariance    , 30 ,  7)
hist("defenseVariance"   , defenseVariance   , 30 ,  8)
hist("spAttackVariance"  , spAttackVariance  , 30 ,  9)
hist("spDefenseVariance" , spDefenseVariance , 30 , 10)
hist("attack0"           , attack0           , 24 , 11)
hist("attack1"           , attack1           , 24 , 12)

plt.show()
