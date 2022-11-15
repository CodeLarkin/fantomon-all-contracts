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

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IFantomonRoyalties.sol";

/**************************************************************************
 * This contract handles royalties for a SPECIFIC Fantomon card.
 * When a player feeds/fights a Fantomon to lvl 25, this contract is cloned
 * for that individual Fantomon. Via this mechanism, each individual
 * Fantomon can have its royalties split between 4 players (those who
 * leveled the Fantomon to 25, 50, 75 and 100), and the two devs.
 **************************************************************************/
contract FantomonRoyaltiesPerMon is ReentrancyGuard {

    bool initialized_;

    uint256 public fantomonId_;
    IFantomonRoyalties public parent_;  // the FantomonRoyalties Contract address

    address payable public lvl25Receiver_;
    address payable public lvl50Receiver_;
    address payable public lvl75Receiver_;
    address payable public lvl100Receiver_;

    // can't use a contructor when using the CloneFactory pattern
    function init(address payable _parent, uint256 _fantomonId, address payable _lvl25er) external {
        require(!initialized_, "Already initialized");
        initialized_ = true;
        parent_        = IFantomonRoyalties(_parent);
        fantomonId_    = _fantomonId;
        lvl25Receiver_ = _lvl25er;  // contract is initialized when Fantomon is leveled to 25
    }

    function  _setReceiver(address payable _address, uint8 _receiverIdx) external {
        // _receiverIdx 0: lvl50, 1: lvl75, 2+: lvl100
        require(msg.sender == address(parent_), "Only FantomonRoyalties contract can set receiver");

        if (_receiverIdx == 0) {
            lvl50Receiver_ = _address;
        } else if (_receiverIdx == 1) {
            lvl75Receiver_ = _address;
        } else {  // if (_receiverIdx == 1) {
            lvl100Receiver_ = _address;
        }
    }

    receive() external payable nonReentrant {
        uint256 perShareRoyalties = msg.value / parent_.royaltyShares_();

        // pay lvl25Receiver_ - lvl25Receiver is always non-zero as it is initialized on contract-creation
        // don't care if it fails - will just pay larkin_ and water_ if so
        lvl25Receiver_.call{value: perShareRoyalties}("");

        if (lvl50Receiver_  != address(0)) {
            // don't care if it fails (e.g. if receiver is an unpayable contract) - will just pay larkin_ and water_ if so
            lvl50Receiver_.call{value: perShareRoyalties}("");
        }
        if (lvl75Receiver_  != address(0)) {
            // don't care if it fails (e.g. if receiver is an unpayable contract) - will just pay larkin_ and water_ if so
            lvl75Receiver_.call{value: perShareRoyalties}("");
        }
        if (lvl100Receiver_ != address(0)) {
            // don't care if it fails (e.g. if receiver is an unpayable contract) - will just pay larkin_ and water_ if so
            lvl100Receiver_.call{value: perShareRoyalties}("");
        }
        // rest sent to parent royalties contract to be split by devs
        Address.sendValue(payable(parent_), address(this).balance);
    }

    // ERC20s cannot be automatically funnelled on receival, hence the withdraw function
    function withdrawERC20(address _erc20) external nonReentrant {
        IERC20 erc20 = IERC20(_erc20);

        uint256 remainingRoyalties = erc20.balanceOf(address(this));
        uint256 perShareRoyalties = remainingRoyalties / parent_.royaltyShares_();

        // pay lvl25Receiver_ - lvl25Receiver is always non-zero as it is initialized on contract-creation
        erc20.transfer(lvl25Receiver_, perShareRoyalties);
        remainingRoyalties -= perShareRoyalties;

        if (lvl50Receiver_  != address(0)) {
            erc20.transfer(lvl50Receiver_, perShareRoyalties);
            remainingRoyalties -= perShareRoyalties;
        }
        if (lvl75Receiver_  != address(0)) {
            erc20.transfer(lvl75Receiver_, perShareRoyalties);
            remainingRoyalties -= perShareRoyalties;
        }
        if (lvl100Receiver_ != address(0)) {
            erc20.transfer(lvl100Receiver_, perShareRoyalties);
            remainingRoyalties -= perShareRoyalties;
        }
        // rest sent to parent royalties contract to be split by devs
        erc20.transfer(payable(parent_), erc20.balanceOf(address(this)));
    }
}
