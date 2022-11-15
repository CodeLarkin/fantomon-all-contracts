/*
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
*/
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./IFantomonTrainerInteractive.sol";
import "./IFantomonAttributes.sol";
import "./IFantomonStore.sol";
import "./IFantomonRoyalties.sol";
import "./IFantomonGraphics.sol";

import "./IFantomonRegistry.sol";

/**************************************************************************
 * A top-level registry of important Fantomon contracts that may need
 * to be referenced by other contracts in the ecosystem.
 * One common place to update addresses such that the information
 * trickles down to leaf contracts.
 **************************************************************************/
contract FantomonRegistry is IFantomonRegistry, Ownable {

    IFantomonTrainerInteractive public ftNFT_;
    address public ftstore_;  // placeholder for Trainer storage
    ERC721 public fmonNFT_;
    IFantomonStore public fstore_;
    IFantomonRoyalties public royalties_;
    address public feeding_;
    address public fighting_;
    address public dojo_;
    address public morphing_;
    IFantomonGraphics public ftgraphics_;
    IFantomonGraphics public fgraphics_;

    mapping(string => address) public others_;

    function setFtNFT(address _ftNFT) external onlyOwner {
        ftNFT_ = IFantomonTrainerInteractive(_ftNFT);
    }
    function setFtstore(address _ftstore) external onlyOwner {
        ftstore_ = _ftstore;
    }
    function setFmonNFT(address _fmonNFT) external onlyOwner {
        fmonNFT_ = ERC721(_fmonNFT);
    }
    function setFstore(address _fstore) external onlyOwner {
        fstore_ = IFantomonStore(_fstore); // core fantomon info storage
    }
    function setRoyalties(address payable _royalties) external onlyOwner {
        royalties_ = IFantomonRoyalties(_royalties);
    }
    function setFeeding(address _feeding) external onlyOwner {
        feeding_ = _feeding;
    }
    function setFighting(address _fighting) external onlyOwner {
        fighting_ = _fighting;
    }
    function setDojo(address _dojo) external onlyOwner {
        dojo_ = _dojo;
    }
    function setMorphing(address _morphing) external onlyOwner {
        morphing_ = _morphing;
    }
    function setFtgraphics(address _ftgraphics) external onlyOwner {
        ftgraphics_ = IFantomonGraphics(_ftgraphics);
    }
    function setFgraphics(address _fgraphics) external onlyOwner {
        fgraphics_ = IFantomonGraphics(_fgraphics);
    }
    // add any other contracts to be accessed via others_ map (string key)
    function setOther(address _contract, string memory _key) external onlyOwner {
        others_[_key] = _contract;
    }
}
