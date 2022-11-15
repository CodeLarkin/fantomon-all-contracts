import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "./IFantomonTrainer.sol";

interface IFantomonTrainerGraphics {
    function tokenURI(uint256 _tokenId, IFantomonTrainer _trainers) external view returns (string memory);
    function tokenURIEmbeddable(uint256 _tokenId, IFantomonTrainer _trainers, bool _embed) external view returns (string memory);
    function getImageURI(uint256 _tokenId, IFantomonTrainer _trainers) external view returns (string memory);
}

interface ERC721NFT is IERC721, IERC721Enumerable, IERC721Metadata {
}
