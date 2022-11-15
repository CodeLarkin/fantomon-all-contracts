// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {FantomonLib} from "./FantomonLib.sol";

interface IFantomonStore {
    function initStarterFmon(uint256 _tokenId, address _sender,
                             uint256 _courage, uint256 _healing, uint8 _choice) external;
    function initFmon(uint256 _tokenId, address _sender,
                      uint8 _class,  uint8 _homeworld,
                      uint8 _rarity, uint256 _courage, uint256 _healing) external;

    function names_(uint256) external view returns (string calldata);
    function fmon(uint256 _tokenId) external view returns (FantomonLib.Fmon memory);
    function fainted(uint256 _tokenId) external returns (bool);
    function getLvl(uint256 _tokenId) external view returns (uint8);
    function getMorph(uint256 _tokenId) external view returns (uint8);
    function getXp(uint256 _tokenId) external view returns (uint48);
    function getDmg(uint256 _tokenId) external view returns (uint48);
    function getNutrients(uint256 _tokenId) external view returns (FantomonLib.Stats memory);
    function getMastery(uint256 _tokenId) external view returns (FantomonLib.Stats memory);
    function getXpNutrients(uint256 _tokenId) external view returns (uint48, FantomonLib.Stats memory);
    function getXpMastery  (uint256 _tokenId) external view returns (uint48, FantomonLib.Stats memory);
    function getScaledStats(uint256 _tokenId) external view returns (FantomonLib.Stats memory);
    function getAttributes(uint256 _tokenId) external view returns (FantomonLib.Attributes memory);
    function getSpecies(uint256 _tokenId) external view returns (uint8);
    function getModifiers(uint256 _tokenId) external view returns (FantomonLib.Modifiers memory);
    function getAttacks(uint256 _tokenId) external view returns (FantomonLib.Attacks memory);

    function _heal(uint256 _tokenId, uint48 _amount, bool _force) external returns (bool);
    function _takeDamage(uint256 _tokenId, uint48 _dmg) external returns (bool);

    function _boostXpNutrients(uint256 _tokenId, FantomonLib.StatBoost memory _boost) external;
    function _boostXpMastery  (uint256 _tokenId, FantomonLib.StatBoost memory _boost) external;
    function _changeAttack(uint256 _tokenId, uint8 _slotIdx, uint8 _atkIdx) external;
    function _morph(uint256 _tokenId) external;
}
