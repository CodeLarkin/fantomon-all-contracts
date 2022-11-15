// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IFantomonArt {
    function PNGS(uint256 _species) external view returns (string memory);
}
