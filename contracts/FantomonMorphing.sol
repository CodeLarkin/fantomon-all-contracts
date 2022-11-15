/*
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
*/
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IFantomonRegistry.sol";
import "./IFantomonStore.sol";

/**************************************************************************
 * Expose functions to user for morphing after level 50
 * Call FantomonStore contract to apply the morph to Fmon storage.
 **************************************************************************/
contract FantomonMorphing is Ownable {
    using FantomonLib for FantomonLib.Fmon;

    uint8  public MAX_MORPH = 1;
    uint48 public MORPH_XP = 125000000000;

    IFantomonRegistry public registry_;

    constructor(IFantomonRegistry _registry) {
        registry_ = _registry;
    }

    // Allow morphs past 1?
    function setMaxMorph(uint8 _max) external onlyOwner {
        MAX_MORPH = _max;
    }

    // User function to morph an Fmon
    function morph(uint256 _tokenId) external {
        IFantomonStore fstore = registry_.fstore_();

        require(registry_.fmonNFT_().ownerOf(_tokenId) == msg.sender, "Only token owner can");

        uint8 morphed = fstore.getMorph(_tokenId);
        uint8 species = fstore.getSpecies(_tokenId);

        require(morphed < MAX_MORPH, "Already morphed");
        require(morphable(species), "Unmorphable species");

        fstore._morph(_tokenId);
    }

    // Helpers to check if an Fmon is morphable

    function morphable(uint8 _species) public pure returns (bool) {
        return _species == 9
            || _species == 11
            || _species == 24
            || _species == 33
            || _species == 39;
    }

    function morphableFmon(uint256 _tokenId) external view returns (bool) {
        uint8 species = registry_.fstore_().fmon(_tokenId).attrs.species;
        return species == 9
            || species == 11
            || species == 24
            || species == 33
            || species == 39;
    }
}
