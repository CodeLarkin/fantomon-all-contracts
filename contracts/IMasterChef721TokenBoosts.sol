// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IMasterChef721TokenBoosts {
    function getBoost(uint256 _tokenId) external view returns (uint256);
}
