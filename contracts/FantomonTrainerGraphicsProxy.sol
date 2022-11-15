import "@openzeppelin/contracts/access/Ownable.sol";
import "./IFantomonTrainerGraphicsV2.sol";

contract FantomonTrainerGraphicsProxy is IFantomonTrainerGraphicsV2, Ownable {
    IFantomonTrainerGraphicsV2 graphics_;

    function setGraphicsContract(address _graphics) external onlyOwner {
        graphics_ = IFantomonTrainerGraphicsV2(_graphics);
    }

    function      imageURI(uint256 _tokenId) external view returns (string memory) {
        return graphics_.imageURI(_tokenId);
    }
    function    overlayURI(uint256 _tokenId) external view returns (string memory) {
        return graphics_.overlayURI(_tokenId);
    }
    function iosOverlayURI(uint256 _tokenId) external view returns (string memory) {
        return graphics_.iosOverlayURI(_tokenId);
    }
    function      tokenURI(uint256 _tokenId) external view returns (string memory) {
        return graphics_.tokenURI(_tokenId);
    }
}
