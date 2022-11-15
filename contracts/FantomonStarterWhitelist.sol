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
import "./IFantomonWhitelist.sol";

/**************************************************************************
 * Whitelist for Starter mints of Generation 1 Fantomons.
 **************************************************************************/
contract FantomonStarterWhitelist is IFantomonWhitelist, Ownable {
    address[] public whitelist_;
    mapping (address => bool) public isOnWhitelist_;  // can a wallet mint a starter right now

    constructor(address[] memory _list) {
        for (uint16 i = 0; i < _list.length; i++) {
            require(!isOnWhitelist_[_list[i]], "invalid, already on whitelist");
            whitelist_.push(_list[i]);
            isOnWhitelist_[_list[i]] = true;
        }
    }

    function addToWhitelist(address[] memory _list) external onlyOwner {
        for (uint16 i = 0; i < _list.length; i++) {
            require(!isOnWhitelist_[_list[i]], "invalid, already on whitelist");
            whitelist_.push(_list[i]);
            isOnWhitelist_[_list[i]] = true;
        }
    }
}
