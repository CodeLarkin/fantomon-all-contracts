pragma solidity ^0.8.13;

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
import "./FantomonSing.sol";
//import "hardhat/console.sol";

/* Aggregate calls to get list of all species sung to by a trainer */
contract FantomonsSungTo is Ownable {

    IFantomonRegistry public registry_;

    uint8 numSpecies_ = 42;

    constructor(IFantomonRegistry _registry) {
        registry_ = _registry;
    }

    function setNumSpecies(uint8 _numSpecies) external onlyOwner {
        numSpecies_ = _numSpecies;
    }

    function speciesSungTo(uint256 _trainerId) external view returns (bool[] memory) {
        FantomonSing fsing = FantomonSing(registry_.others_('sing'));

        bool[] memory sungTo = new bool[](numSpecies_);
        //console.log("Initialized sungTo array with length %s...", sungTo.length);
        for (uint8 s; s < numSpecies_;) {
            //console.log("Checking if species %s has been sungTo...", s);

            if (fsing.speciesSungTo_(_trainerId, s)) {
                sungTo[s] = true;
            }
            unchecked { s++; }
        }
        //console.log("Done.");
        return sungTo;
    }
}
