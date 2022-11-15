import "@openzeppelin/contracts/access/Ownable.sol";

import "./IFantomonRegistry.sol";

contract FantomonDojo is Ownable {

    IFantomonRegistry public registry_;

    constructor(IFantomonRegistry _registry) {
        registry_ = _registry;
    }

    function learnAttack(uint256 _tokenId, uint8 _slotIdx, uint8 _atkIdx) external {
        IFantomonStore fstore = registry_.fstore_();
        fstore._changeAttack(_tokenId, _slotIdx, _atkIdx);
    }
}
