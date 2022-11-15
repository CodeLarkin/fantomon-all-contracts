// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IFantomonGraphics {
    function imageURI(uint256 _tokenId) external view returns (string memory);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}
