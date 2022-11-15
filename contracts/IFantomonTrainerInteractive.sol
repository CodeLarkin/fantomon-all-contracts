// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IFantomonTrainerInteractive is IERC721Enumerable, IERC721Metadata {

    /**************************************************************************
     * Stats and attributes for all trainers
     **************************************************************************/
    function getKinship(uint256 _tokenId) external view returns (uint256);
    function getFlare(uint256 _tokenId) external view returns (uint256);
    function getCourage(uint256 _tokenId) external view returns (uint256);
    function getWins(uint256 _tokenId) external view returns (uint256);
    function getLosses(uint256 _tokenId) external view returns (uint256);
    /* Stats and attributes for all trainers
     **************************************************************************/

    /**************************************************************************
     * Getters
     **************************************************************************/
    function location_(uint256 _tokenId) external view returns (address);
    function getStatus(uint256 _tokenId) external view returns (uint8);
    function getRarity(uint256 _tokenId) external view returns (uint8);
    function getClass(uint256 _tokenId) external view returns (uint8);
    function getFace(uint256 _tokenId) external view returns (uint8);
    function getHomeworld(uint256 _tokenId) external view returns (uint8);
    function getTrainerName(uint256 _tokenId) external view returns (string memory);
    function getHealing(uint256 _tokenId) external view returns (uint256);

    function fantomonsEnabled_(address _fantomon) external view returns (bool);
    function arenasEnabled_(address _arena) external view returns (bool);
    /* End getters
     **************************************************************************/

    /**************************************************************************
     * Interactions callable by location contracts
     **************************************************************************/
    function _enterBattle(uint256 _tokenId) external;
    function _leaveArena(uint256 _tokenId, bool _won) external;
    function _leaveHealingRift(uint256 _tokenId) external;
    function _leaveJourney(uint256 _tokenId) external;
    function _leave(uint256 _tokenId) external;
    /* End interactions callable by location contracts
     **************************************************************************/
}
