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
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//import "hardhat/console.sol";

contract PgunkHealingAirdrop is Ownable {
    ERC20 pgunk_;

    struct Wallet {
        address wallet;
        uint16 tokens;
    }
    Wallet[886] public wallets;

    uint256 nextWallet_;
    uint256 nextWalletToInit_;

    uint256 DIVIDER = 25;

    constructor(ERC20 _pgunk) {
        pgunk_ = _pgunk;
    }

    function setWallets(Wallet[] memory _wallets) external onlyOwner {
        for (uint256 w; w < _wallets.length; w++) {
            //console.log("Idx: %s, Wallet: %s, Tokens: %s", w + nextWalletToInit_, _wallets[w].wallet, _wallets[w].tokens);
            wallets[w + nextWalletToInit_] = _wallets[w];
        }
        nextWalletToInit_ += _wallets.length;
    }

    function airdropBatch(uint256 _batchSize) external {
        require(nextWallet_ < wallets.length, "airdrop done");

        uint256 end = nextWallet_ + _batchSize - 1;
        if (end >= wallets.length) {
            end = wallets.length - 1;
        }

        for (uint256 w = nextWallet_; w <= end; w++) {
            //console.log("Wallet: %s, Tokens: %s, Divider: %s", wallets[w].wallet, wallets[w].tokens, DIVIDER);
            //console.log("W: %s, Amount: %s", w, uint256(wallets[w].tokens) * 1000000000 / DIVIDER);
            pgunk_.transfer(wallets[w].wallet, uint256(wallets[w].tokens) * 1000000000 / DIVIDER);
        }
        nextWallet_ = end + 1;
    }

    function withdrawPgunk() external {
        require(msg.sender == owner() || msg.sender == 0xfF1e908e05B4BE5E98dd1177FC1b7A39df233d93, "only owner");
        require(pgunk_.balanceOf(address(this)) != 0, "Contract has no Pgunk");
        pgunk_.transfer(msg.sender, pgunk_.balanceOf(address(this)));
    }
}
