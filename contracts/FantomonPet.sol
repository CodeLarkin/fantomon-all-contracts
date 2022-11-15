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

contract FantomonPet {

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

        require(_args[0] == 0, "Invalid interaction");  // This contract only supports Pet

        fstore._heal(_fantomonId, uint48(ftNFT.getHealing(_trainerId) * 100000000), false);
    }
}
