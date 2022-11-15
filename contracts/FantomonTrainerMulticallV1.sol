/*
by
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
with help from
░██╗░░░░░░░██╗░█████╗░████████╗███████╗██████╗░██╗░░██╗██████╗░░█████╗░██████╗░
░██║░░██╗░░██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██║░░██║╚════██╗██╔══██╗╚════██╗
░╚██╗████╗██╔╝███████║░░░██║░░░█████╗░░██████╔╝███████║░░███╔═╝██║░░██║░█████╔╝
░░████╔═████║░██╔══██║░░░██║░░░██╔══╝░░██╔══██╗██╔══██║██╔══╝░░██║░░██║░╚═══██╗
░░╚██╔╝░╚██╔╝░██║░░██║░░░██║░░░███████╗██║░░██║██║░░██║███████╗╚█████╔╝██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░╚════╝░╚═════╝░
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "./IFantomonTrainerInteractive.sol";
import "./IFantomonTrainerGraphicsV2.sol";

contract FantomonTrainerMulticallV1 {

    uint256 constant TOTAL_SUPPLY = 10000;

    IFantomonTrainerInteractive trainer_;
    IFantomonTrainerGraphicsV2 graphics_;

    constructor (address _trainer, address _graphics) {
        trainer_  = IFantomonTrainerInteractive(_trainer);
        graphics_ = IFantomonTrainerGraphicsV2(_graphics);
    }


    struct Trainer {
        uint16 tokenId;
        uint64 kinship;
        uint64 flare;
        uint64 healing;
        uint64 courage;
        uint64 wins;
        uint64 losses;
        uint8 rarity;
        uint8 class;
        uint8 face;
        uint8 homeworld;
        uint8 status;
        address owner;
    }
    struct NFT {
        uint256 tokenId;
        string uri;
    }
    struct TrainerNFT {
        uint256 tokenId;
        string uri;
        Trainer trainer;
    }

    function _batchIds(uint256 _batchIdx, uint256 _batchSize) internal pure returns (uint256, uint256) {
        uint256 startTok = 1 + _batchIdx*_batchSize;  // tokenIds start at 1
        uint256 endTok   = 1 + (_batchIdx+1)*_batchSize;
        if (endTok > TOTAL_SUPPLY) {
            endTok = TOTAL_SUPPLY;
        }
        return (startTok, endTok);
    }

    function _batchIdxsOfUser(address _user, uint256 _batchIdx, uint256 _batchSize) internal view returns (uint256, uint256) {
        uint256 startTok = _batchIdx*_batchSize;
        uint256 endTok   = (_batchIdx+1)*_batchSize;
        uint256 bal      = trainer_.balanceOf(_user);
        if (bal < endTok) {
            endTok = bal;
        }
        return (startTok, endTok);
    }

    function tokensOfOwner(address _user, uint256 _batchIdx, uint256 _batchSize) public view returns (uint256[] memory) {
        (uint256 startTok, uint256 endTok) = _batchIdxsOfUser(_user, _batchIdx, _batchSize);

        uint256 idx;
        uint256 tok;
        uint256[] memory tokenIds = new uint256[](_batchSize);
        for (tok = startTok; tok < endTok; tok++) {
            tokenIds[idx] = trainer_.tokenOfOwnerByIndex(_user, tok);
            idx++;
        }
        return tokenIds;
    }

    function urisOfOwner(address _user, uint256 _batchIdx, uint256 _batchSize) public view returns (string[] memory) {
        (uint256 startTok, uint256 endTok) = _batchIdxsOfUser(_user, _batchIdx, _batchSize);

        uint256 idx;
        uint256 tok;
        string[] memory uris = new string[](_batchSize);
        for (tok = startTok; tok < endTok; tok++) {
            uint256 tokenId = trainer_.tokenOfOwnerByIndex(_user, tok);
            uris[idx] = trainer_.tokenURI(tokenId);
            idx++;
        }
        return uris;
    }

    function nftsOfOwner(address _user, uint256 _batchIdx, uint256 _batchSize) public view returns (NFT[] memory) {
        (uint256 startTok, uint256 endTok) = _batchIdxsOfUser(_user, _batchIdx, _batchSize);

        uint256 idx;
        uint256 tok;
        NFT[] memory nfts = new NFT[](_batchSize);
        for (tok = startTok; tok < endTok; tok++) {
            uint256 tokenId = trainer_.tokenOfOwnerByIndex(_user, tok);
            nfts[idx] = NFT(tokenId, trainer_.tokenURI(tokenId));
            idx++;
        }
        return nfts;
    }

    function trainer(uint256 _tokenId) public view returns (Trainer memory) {
        return Trainer(uint16(_tokenId),
                       uint64(trainer_.getKinship(_tokenId)) , uint64(trainer_.getFlare(_tokenId))     ,
                       uint64(trainer_.getHealing(_tokenId)) , uint64(trainer_.getCourage(_tokenId))   ,
                       uint64(trainer_.getWins(_tokenId))    , uint64(trainer_.getLosses(_tokenId))    ,
                       trainer_.getRarity(_tokenId)  , trainer_.getClass(_tokenId)     ,
                       trainer_.getFace(_tokenId)    , trainer_.getHomeworld(_tokenId) ,
                       trainer_.getStatus(_tokenId)  , trainer_.ownerOf(_tokenId));
    }

    function trainersBatch(uint256 _batchIdx, uint256 _batchSize) public view returns (Trainer[] memory) {
        (uint256 startTok, uint256 endTok) = _batchIds(_batchIdx, _batchSize);

        uint256 idx;
        uint256 tok;
        Trainer[] memory trainers = new Trainer[](endTok-startTok);
        for (tok = startTok; tok < endTok; tok++) {
            trainers[idx] = trainer(tok);
            idx++;
        }
        return trainers;
    }

    function trainersOfOwner(address _user, uint256 _batchIdx, uint256 _batchSize) public view returns (Trainer[] memory) {
        (uint256 startTok, uint256 endTok) = _batchIdxsOfUser(_user, _batchIdx, _batchSize);

        uint256 idx;
        uint256 tok;
        Trainer[] memory trainers = new Trainer[](endTok-startTok);
        for (tok = startTok; tok < endTok; tok++) {
            uint256 tokenId = trainer_.tokenOfOwnerByIndex(_user, tok);
            trainers[idx] = trainer(tokenId);
            idx++;
        }
        return trainers;
    }

    function multiviewTrainersOfOwner(address _user, uint256 _batchIdx, uint256 _batchSize) public view returns (TrainerNFT[] memory) {
        (uint256 startTok, uint256 endTok) = _batchIdxsOfUser(_user, _batchIdx, _batchSize);

        uint256 idx;
        uint256 tok;
        TrainerNFT[] memory trainers = new TrainerNFT[](endTok-startTok);
        for (tok = startTok; tok < endTok; tok++) {
            uint256 tokenId = trainer_.tokenOfOwnerByIndex(_user, tok);
            string memory uri = graphics_.tokenURI(tokenId);
            trainers[idx] = TrainerNFT(tokenId, uri, trainer(tokenId));
            idx++;
        }
        return trainers;
    }
}
/*
by
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
with help from
░██╗░░░░░░░██╗░█████╗░████████╗███████╗██████╗░██╗░░██╗██████╗░░█████╗░██████╗░
░██║░░██╗░░██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██║░░██║╚════██╗██╔══██╗╚════██╗
░╚██╗████╗██╔╝███████║░░░██║░░░█████╗░░██████╔╝███████║░░███╔═╝██║░░██║░█████╔╝
░░████╔═████║░██╔══██║░░░██║░░░██╔══╝░░██╔══██╗██╔══██║██╔══╝░░██║░░██║░╚═══██╗
░░╚██╔╝░╚██╔╝░██║░░██║░░░██║░░░███████╗██║░░██║██║░░██║███████╗╚█████╔╝██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░╚════╝░╚═════╝░
*/
