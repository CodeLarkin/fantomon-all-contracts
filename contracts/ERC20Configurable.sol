// SPDX-License-Identifier: GPL-3.0-or-later

//import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


pragma solidity ^0.8.9;


//contract ERC20Configurable is ERC20Burnable {
contract ERC20Configurable is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000000000000*(10**uint(decimals())));
    }
}
