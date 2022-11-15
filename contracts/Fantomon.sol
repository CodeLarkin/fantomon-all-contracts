/*
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


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./IFantomonRegistry.sol";
import "./IFantomonWhitelist.sol";

/**************************************************************************
 * This contract handles the ERC721 functionality of Generation 1 Fantomons
 * Actual Fantomon details are stored via the FantomonStore contract,
 * and attributes and stats are rolled via FantomonAttribues.
 * Feeding, Fighting, Morphing, Petting and other interactions occur
 * in other modules and modify the storage of FantomonStore.
 **************************************************************************/
contract Fantomon is ERC721, IERC2981, ReentrancyGuard, Ownable {

    /**************************************************************************
     * Constants
     **************************************************************************/
    // Bytes4 Code for EIP-2981
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    address constant private LARKIN = 0x46E50dc219BA5A26890Dc99cDe4f4AC2a48011e9;
    address constant private WATER  = 0x692b54A541eE5590F551E002b0967b7981fF36F5;

    uint256 constant private PRICE = 15 ether;
    uint256 constant private MAX_MINT = 20;

    uint256 constant private STARTERS_SUPPLY_CAP = 612;
    uint256 constant private GEN1_SUPPLY_CAP = 20000;
    /* End constants
     **************************************************************************/


    /**************************************************************************
     * Globals
     **************************************************************************/
    IFantomonRegistry public registry_;
    bool public publicSale_;  // is the public sale live yet?

    uint256 public nextStarter_ = 1;  // next unminted Starter
    uint256 public nextGen1_ = STARTERS_SUPPLY_CAP + 1;  // next unminted Gen1

    bool public trainerRequired_ = true;  // do you need a trainer to mint?

    IFantomonWhitelist public whitelist_;  // whitelist for starters
    mapping (address => bool) public mintedStarter_;  // has this wallet already minted a starter
    /* End globals
     **************************************************************************/

    constructor(IFantomonRegistry _registry,
                IFantomonWhitelist _whitelist) ERC721("Fantomon Gen1", "FMONG1") Ownable() {
        registry_ = IFantomonRegistry(_registry);
        whitelist_ = _whitelist;
    }

    /**************************************************************************
     * Getters
     **************************************************************************/
    // Total supply including Starters and standard Gen 1
    function totalSupply() external view returns (uint256) {
        //           gen1 supply + starter supply
        return (nextGen1_ - 613) + (nextStarter_ - 1);
    }

    // Token URI and graphics functions: image and metadata construction
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return registry_.fgraphics_().tokenURI(_tokenId);
    }

    // ERC2981 override for royaltyInfo(uint256, uint256)
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override(IERC2981) returns (address _receiver, uint256 _royaltyAmount) {
        (_receiver, _royaltyAmount) = registry_.royalties_().royaltyInfo(_tokenId, _salePrice);
    }

    // Should support ERC721, 165 and 2981
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }
    /* Getters
     **************************************************************************/

    /**************************************************************************
     * onlyOwner Setters
     **************************************************************************/
    function setRegistry(IFantomonRegistry _registry) external onlyOwner {
        registry_ = _registry;
    }
    function togglePublicSale() external onlyOwner {
        publicSale_ = !publicSale_;
    }
    function toggleTrainerRequired() external onlyOwner {
        trainerRequired_ = !trainerRequired_;
    }
    /* onlyOwner Setters
     **************************************************************************/

    /**************************************************************************
     * Mint
     **************************************************************************/
    function mintStarter(uint256 _trainerId, uint8 _choice) public {
        address sender = _msgSender();
        IFantomonTrainerInteractive ftNFT = registry_.ftNFT_();

        require(sender == tx.origin, "Cant mint from contract");
        require(!mintedStarter_[sender] && whitelist_.isOnWhitelist_(sender), "Not approved to mint Starter");

        require(_choice < 2, "Invalid choice");
        require(nextStarter_ <= STARTERS_SUPPLY_CAP, "Cant mint > cap");

        require(ftNFT.ownerOf(_trainerId) == sender, "Dont own that trainer");

        registry_.fstore_().initStarterFmon(nextStarter_,
                                            sender, ftNFT.getCourage(_trainerId), ftNFT.getHealing(_trainerId), _choice);
        mintedStarter_[sender] = true;

        nextStarter_++;  // incrementing nextStarter_ before _safeMint() prevents any reentrancy concerns with onERC721Received

        _safeMint(sender, nextStarter_-1);
    }

    function mint(uint256 _trainerId, uint8 _amount) public payable {
        require(publicSale_, "Sale not public");

        address sender = _msgSender();
        IFantomonTrainerInteractive ftNFT = registry_.ftNFT_();
        require(sender == tx.origin, "Cant mint from contract");
        require(_amount > 0 && _amount <= MAX_MINT, "Invalid mint amnt");
        require(nextGen1_ + _amount - STARTERS_SUPPLY_CAP - 1 <= GEN1_SUPPLY_CAP, "Cant mint > cap");
        require(msg.value == PRICE*_amount, "Incorrect amnt of FTM");

        uint8   class   = 0;
        uint8   world   = 0;
        uint8   rarity  = 0;
        uint256 courage = 1;
        uint256 healing = 1;

        require(_trainerId != 0 || !trainerRequired_, "Need to provide a trainerId");

        if (_trainerId != 0) {
            require(ftNFT.ownerOf(_trainerId) == sender, "Dont own that trainer");
            class   = ftNFT.getClass(_trainerId);
            world   = ftNFT.getHomeworld(_trainerId);
            rarity  = ftNFT.getRarity(_trainerId);
            courage = ftNFT.getCourage(_trainerId);
            healing = ftNFT.getHealing(_trainerId);
        }

        uint256 tokenId = nextGen1_;
        nextGen1_ += _amount;  // incrementing nextStarter_ before _safeMint() prevents any reentrancy concerns with onERC721Received
        for (uint8 i = 0; i < _amount; i++) {
            registry_.fstore_().initFmon(tokenId, sender, class, world, rarity, courage, healing);

            _safeMint(sender, tokenId);
            tokenId++;
        }
    }
    /* End mint
     **************************************************************************/

    /**************************************************************************
     * Payments
     **************************************************************************/
    function withdraw() external {
        require(_msgSender() == owner() || _msgSender() == LARKIN || _msgSender() == WATER, "Not on team");

        Address.sendValue(payable(LARKIN), address(this).balance / 2);
        Address.sendValue(payable(WATER),  address(this).balance);
    }

    // Contract should never be paid, but just in case a marketplace accidentally pays this contract...
    receive() external payable {}
    /* End payments
     **************************************************************************/
}
/**************************************************************************
 * Varibale naming convention:
 *     Contract-level constants are ALL_CAPS
 *     Contract-level variables are camelCase_ ending with an underscore
 *     Function arguments are _camelCase starting with an underscore
 *     Variables in functions are camelCase with no underscores
 **************************************************************************/
/*
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
