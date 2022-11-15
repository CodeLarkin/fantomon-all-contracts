/*
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
*/
import "./IFantomonRegistry.sol";
import "./IFantomonTrainerInteractive.sol";
import "./IFantomonStore.sol";

/**************************************************************************
 * Sing interaction to be called by FantomonTrainer contract.
 * Rules:
 *    A Trainer can only Sing to each Species one time
 *    Must own a Fantomon to sing to it
 *    You can sing to the same Fantomon with multiple trainers
 *
 * Sing to all Species
 * and you've essentially checked each Species off the list
 **************************************************************************/
contract FantomonSing {

    IFantomonRegistry public registry_;

    mapping(uint256 => mapping(uint8 => bool)) public speciesSungTo_;

    constructor(IFantomonRegistry _registry) {
        registry_ = _registry;
    }

    function interact(uint256 _trainerId, uint256 _fantomonId, uint256[] calldata _args) external {
        IFantomonTrainerInteractive ftNFT = registry_.ftNFT_();
        IFantomonStore fstore = registry_.fstore_();

        require(msg.sender == address(ftNFT), "Only trainer contract can");
        require(ftNFT.ownerOf(_trainerId) == registry_.fmonNFT_().ownerOf(_fantomonId), "Must own trainer and fantomon");

        require(_args[0] == 2, "Invalid interaction");  // This contract only supports Sing

        uint8 species = fstore.getAttributes(_fantomonId).species;
        require(!speciesSungTo_[_trainerId][species], "Trainer already sang to that species");
        speciesSungTo_[_trainerId][species] = true;
    }
}
