import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IFantomonRegistry.sol";
import "./CosmicGunk.sol";

contract GunkMixer is ReentrancyGuard, Ownable {

    IFantomonRegistry registry_;
    ERC20 egunk_;
    ERC20 bgunk_;
    CosmicGunk cgunk_;

    uint256 public ePerB_ = 10;
    bool public invertEPerB_ = false;

    // CGUNK amount modifier fraction (1025/1000 = x1.025 = 2.5% boost)
    uint256 public CMODIFIER_NUM = 1025;
    uint256 public CMODIFIER_DEN = 1000;


    constructor(IFantomonRegistry _registry, ERC20 _egunk, ERC20 _bgunk, CosmicGunk _cgunk) {
        registry_ = _registry;
        egunk_    = _egunk;
        bgunk_    = _bgunk;
        cgunk_    = _cgunk;
    }

    function setEgunkPerBgunk(uint256 _ePerB) external onlyOwner {
        ePerB_ = _ePerB;
    }

    function toggleInvertEPerB() external onlyOwner {
        invertEPerB_ = !invertEPerB_;
    }

    function setCmodifierRatio(uint256 _numerator, uint256 _denominator) external onlyOwner {
        CMODIFIER_NUM = _numerator;
        CMODIFIER_DEN = _denominator;
    }

    function mix(uint256 _eAmount, uint256 _bAmount, uint256 _trainerId, uint256 _fantomonId) external nonReentrant {
        require(validRatio(_eAmount, _bAmount), "Wrong EGUNK/BGUNK ratio");
        // burn EGUNK and BGUNK
        egunk_.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _eAmount);
        bgunk_.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _bAmount);
        // calculate amount of CGUNK to mint
        uint256 cAmount = _bAmount;
        if (_trainerId != 0) {
            IFantomonTrainerInteractive ftNFT = registry_.ftNFT_();
            require(ftNFT.ownerOf(_trainerId) == msg.sender, "Dont own that trainer");
            if (ftNFT.getHomeworld(_trainerId) == 0) {
                cAmount = (cAmount * CMODIFIER_NUM) / CMODIFIER_DEN;
            }
        }
        if (_fantomonId != 0) {
            require(registry_.fmonNFT_().ownerOf(_fantomonId) == msg.sender, "Dont own that trainer");
            if (registry_.fstore_().getAttributes(_fantomonId).typ == 5) {
                cAmount = (cAmount * CMODIFIER_NUM) / CMODIFIER_DEN;
            }
        }
        // mint CGUNK to sender
        cgunk_.mint(msg.sender, cAmount);
    }

    function mockMix(uint256 _eAmount, uint256 _bAmount, uint256 _trainerId, uint256 _fantomonId) external returns (uint256) {
        require(validRatio(_eAmount, _bAmount), "Wrong EGUNK/BGUNK ratio");
        // calculate amount of CGUNK to mint
        uint256 cAmount = _bAmount;
        if (_trainerId != 0) {
            IFantomonTrainerInteractive ftNFT = registry_.ftNFT_();
            require(ftNFT.ownerOf(_trainerId) == msg.sender, "Dont own that trainer");
            if (ftNFT.getHomeworld(_trainerId) == 0) {
                cAmount = (cAmount * CMODIFIER_NUM) / CMODIFIER_DEN;
            }
        }
        if (_fantomonId != 0) {
            require(registry_.fmonNFT_().ownerOf(_fantomonId) == msg.sender, "Dont own that trainer");
            if (registry_.fstore_().getAttributes(_fantomonId).typ == 5) {
                cAmount = (cAmount * CMODIFIER_NUM) / CMODIFIER_DEN;
            }
        }
        // mint CGUNK to sender
        return cAmount;
    }

    function validRatio(uint256 _eAmount, uint256 _bAmount) public view returns (bool) {
        if (invertEPerB_) {
            return _eAmount * ePerB_ == _bAmount;
        } else {
            return _eAmount == ePerB_ * _bAmount;
        }
    }

    function getEgunkForBgunk(uint256 _bAmount) external view returns (uint256) {
        if (invertEPerB_) {
            return _bAmount / ePerB_;
        } else {
            return _bAmount * ePerB_;
        }
    }

    function getBgunkForEgunk(uint256 _eAmount) external view returns (uint256) {
        if (invertEPerB_) {
            return _eAmount * ePerB_;
        } else {
            return _eAmount / ePerB_;
        }
    }
}
