/*
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IFantomonArt.sol";

contract FantomonArt is IFantomonArt, Ownable {
    string[] public PNGS;

    function changePNG(uint256 _idx, string memory _png) external onlyOwner {
        PNGS[_idx] = _png;
    }
    function addPNG(string memory _png) external onlyOwner {
        PNGS.push(_png);
    }
}
