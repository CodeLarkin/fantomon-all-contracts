import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "./IFantomonTrainer.sol";

interface IFantomonTrainerGraphicsV2 {
    function      imageURI(uint256 _tokenId) external view returns (string memory);
    function    overlayURI(uint256 _tokenId) external view returns (string memory);
    function iosOverlayURI(uint256 _tokenId) external view returns (string memory);
    function      tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface ERC721NFT is IERC721, IERC721Enumerable, IERC721Metadata {
}
