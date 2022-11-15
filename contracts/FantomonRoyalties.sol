/*
by
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
with help from
░██╗░░░░░░░██╗░█████╗░████████╗███████╗██████╗░██╗░░██╗██████╗░░█████╗░██████╗░
░██║░░██╗░░██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██║░░██║╚════██╗██╔══██╗╚════██╗
░╚██╗████╗██╔╝███████║░░░██║░░░█████╗░░██████╔╝███████║░░███╔═╝██║░░██║░█████╔╝
░░████╔═████║░██╔══██║░░░██║░░░██╔══╝░░██╔══██╗██╔══██║██╔══╝░░██║░░██║░╚═══██╗
░░╚██╔╝░╚██╔╝░██║░░██║░░░██║░░░███████╗██║░░██║██║░░██║███████╗╚█████╔╝██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░╚════╝░╚═════╝░
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./CloneFactory.sol";

import "./IFantomonRegistry.sol";
import "./IFantomonRoyalties.sol";
import "./FantomonRoyaltiesPerMon.sol";

/**************************************************************************
 * This contract handles royalties for Fantomons. The base case is that
 * all royalties are paid to this contract and then split between the devs.
 * When a player feeds/fights a Fantomon to lvl 25, this contract deploys
 * a contract [clone] to handle royalties for THAT SPECIFIC Fantomon.
 **************************************************************************/
contract FantomonRoyalties is IFantomonRoyalties, CloneFactory, ReentrancyGuard, Ownable {

    IFantomonRegistry public registry_;

    address payable public perMonLibraryAddress_;  // template/library for per-mon royalties - cloned per Fantomon at lvl25

    // devs
    address payable public larkin_;
    address payable public water_;

    uint256 public royaltyShares_;  // %royalties - also each lvler gets 1 share worth of of royalties

    mapping(uint256 => FantomonRoyaltiesPerMon) public perMonRoyaltiesContract_;  // royalties contracts for each tokenId

    constructor(IFantomonRegistry _registry) {
        registry_ = _registry;

        perMonLibraryAddress_ = payable(new FantomonRoyaltiesPerMon());  // deploy template/library for cloning

        larkin_ = payable(0x46E50dc219BA5A26890Dc99cDe4f4AC2a48011e9);
        water_  = payable(0x692b54A541eE5590F551E002b0967b7981fF36F5);
        royaltyShares_ = 6;
    }

    // Setters
    function setRegistry(address _registry) external onlyOwner {
        registry_ = IFantomonRegistry(_registry);
    }
    function setRoyaltyShares(uint256 _royaltyShares) external onlyOwner {
        royaltyShares_ = _royaltyShares;
    }
    function setLarkin(address payable _larkin) external onlyOwner {
        larkin_ = _larkin;
    }
    function setWater(address payable _water) external onlyOwner {
        water_ = _water;
    }

    // Set royalties receiver for each special level 25/50/75/100
    // For 25, clone the per-mon libary/template and deploy a royalties
    // contract for that tokenId
    function  set25Receiver(uint256 _tokenId, address _receiver) external {
        require(msg.sender == address(registry_.fighting_()) || msg.sender == address(registry_.feeding_()), "Only FantomonFighting or Feeding Contract can set the royalties receiver");
        // lvl25Receiver_ is set on contract creation/cloning
        FantomonRoyaltiesPerMon royalClone = FantomonRoyaltiesPerMon(createClone(perMonLibraryAddress_));
        royalClone.init(payable(this), _tokenId, payable(_receiver));
        perMonRoyaltiesContract_[_tokenId] = royalClone;
    }
    function  set50Receiver(uint256 _tokenId, address _receiver) external {
        require(msg.sender == address(registry_.fighting_()) || msg.sender == address(registry_.feeding_()), "Only FantomonFighting or Feeding Contract can set the royalties receiver");
        perMonRoyaltiesContract_[_tokenId]._setReceiver(payable(_receiver), 0);
    }
    function  set75Receiver(uint256 _tokenId, address _receiver) external {
        require(msg.sender == address(registry_.fighting_()) || msg.sender == address(registry_.feeding_()), "Only FantomonFighting or Feeding Contract can set the royalties receiver");
        perMonRoyaltiesContract_[_tokenId]._setReceiver(payable(_receiver), 1);
    }
    function set100Receiver(uint256 _tokenId, address _receiver) external {
        require(msg.sender == address(registry_.fighting_()) || msg.sender == address(registry_.feeding_()), "Only FantomonFighting or Feeding Contract can set the royalties receiver");
        perMonRoyaltiesContract_[_tokenId]._setReceiver(payable(_receiver), 2);
    }

    // called by Fantomon.sol to get EIP2981 info - royalties per tokenId
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address _receiver, uint256 _royaltyAmount) {
        // if per-mon royalties are not initialized, this contract receives all - otherwise per-mon contract for this tokenID receives
        _receiver = address(perMonRoyaltiesContract_[_tokenId]) == address(0) ? address(this) : address(perMonRoyaltiesContract_[_tokenId]);
        _royaltyAmount = (_salePrice / 100) * royaltyShares_;  // royaltyShares is also %royalties
    }

    // Before a Fantomon reaches level 25, all of its royalties are sent to this contract
    function withdraw() external {
        require(msg.sender == owner() || msg.sender == larkin_ || msg.sender == water_, "Not on team");

        Address.sendValue(payable(larkin_), address(this).balance / 2);
        Address.sendValue(payable(water_),  address(this).balance);
    }
    function withdrawERC20(address _erc20) external nonReentrant {
        require(msg.sender == owner() || msg.sender == larkin_ || msg.sender == water_, "Not on team");
        IERC20 erc20 = IERC20(_erc20);

        erc20.transfer(larkin_, erc20.balanceOf(address(this)) / 2);
        erc20.transfer(water_,  erc20.balanceOf(address(this)));
    }

    receive() external payable {}
}
