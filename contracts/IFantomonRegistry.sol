import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./IFantomonTrainerInteractive.sol";
import "./IFantomonStore.sol";
import "./IFantomonRoyalties.sol";
import "./IFantomonGraphics.sol";
import "./IFantomonWhitelist.sol";

interface IFantomonRegistry {
    function ftNFT_() external view returns (IFantomonTrainerInteractive);
    function ftstore_() external view returns (address);
    function fmonNFT_() external view returns (ERC721);
    function fstore_() external view returns (IFantomonStore);

    function royalties_() external view returns (IFantomonRoyalties);
    function feeding_() external view returns (address);
    function fighting_() external view returns (address);
    function dojo_() external view returns (address);
    function morphing_() external view returns (address);
    function ftgraphics_() external view returns (IFantomonGraphics);
    function fgraphics_() external view returns (IFantomonGraphics);

    function others_(string memory) external view returns (address);
}
