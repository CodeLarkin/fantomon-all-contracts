// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IFantomonRegistry.sol";
import "./FantomonStore.sol";
import "./IMasterChef721TokenBoosts.sol";

import {FantomonLib} from "./FantomonLib.sol";


contract MasterChef721TokenBoosts is IMasterChef721TokenBoosts {
    IFantomonRegistry registry_;

    constructor(IFantomonRegistry _registry) {
        registry_ = _registry;
    }

    function getBoost(uint256 _tokenId) external view override returns (uint256 _boost) {
        IFantomonStore fstore = registry_.fstore_();

        FantomonLib.Attributes memory attrs = fstore.getAttributes(_tokenId);
        FantomonLib.Attacks memory attacks = fstore.getAttacks(_tokenId);
        uint8 typ = attrs.typ;
        uint8 mood = attrs.mood;
        uint8 essc = attrs.essence;
        uint8 attack0 = attacks.attack0;
        uint8 attack1 = attacks.attack1;

            // Aqua + Meta Splash
            // Aqua + Swift
        if ((typ == 0 && (attack0 ==  4 || attack1 ==  4 || essc ==  3)) ||
            // Chaos + Eclipse Flash
            // Chaos + Fiery
            (typ == 1 && (attack0 == 12 || attack1 == 12 || essc == 11)) ||
            // Cosmic + Mush
            // Cosmic + Cosmic Veteran
            (typ == 2 && (attack0 == 10 || attack1 == 10 || mood ==  4)) ||
            // Demon + Spook
            // Demon + Agile
            (typ == 3 && (attack0 ==  6 || attack1 ==  6 || essc ==  5)) ||
            // Fairy + Chorus of Skulls
            // Fairy + Very Playful
            (typ == 4 && (attack0 == 23 || attack1 == 23 || mood ==  2)) ||
            // Gunk + Gunk Barrage
            // Gunk + Often Munchy
            (typ == 5 && (attack0 ==  2 || attack1 ==  2 || mood ==  0)) ||
            // Mineral + Tomb Crush
            // Mineral + Battle Ready
            (typ == 6 && (attack0 ==  3 || attack1 ==  3 || mood ==  3)) ||
            // Plant + Resurrect
            // Plant + Mischievous
            (typ == 7 && (attack0 == 21 || attack1 == 21 || mood ==  1))) {

            _boost = 1;
        } else {
            _boost = 0;
        }
    }
}
