// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {FantomonLib} from "./FantomonLib.sol";

interface IFantomonAttributes {
    function randStarter(uint256 _tokenId, address _sender,
                         uint256 _courage, uint256 _healing, uint8 _choice) external view returns (FantomonLib.Fmon memory _fmon);
    function randFmon(uint256 _tokenId, address _sender,
                      uint8 _class, uint8 _homeworld,
                      uint8 _rarity, uint256 _courage, uint256 _healing) external view returns (FantomonLib.Fmon memory _fmon);
}
