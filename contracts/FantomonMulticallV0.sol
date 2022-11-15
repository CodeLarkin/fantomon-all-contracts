/*
░██╗░░░░░░░██╗░█████╗░████████╗███████╗██████╗░██╗░░██╗██████╗░░█████╗░██████╗░
░██║░░██╗░░██║██╔══██╗╚══██╔══╝██╔════╝██╔══██╗██║░░██║╚════██╗██╔══██╗╚════██╗
░╚██╗████╗██╔╝███████║░░░██║░░░█████╗░░██████╔╝███████║░░███╔═╝██║░░██║░█████╔╝
░░████╔═████║░██╔══██║░░░██║░░░██╔══╝░░██╔══██╗██╔══██║██╔══╝░░██║░░██║░╚═══██╗
░░╚██╔╝░╚██╔╝░██║░░██║░░░██║░░░███████╗██║░░██║██║░░██║███████╗╚█████╔╝██████╔╝
░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝░╚════╝░╚═════╝░

░█████╗░███╗░░██╗██████╗░  ██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██╔══██╗████╗░██║██╔══██╗  ██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
███████║██╔██╗██║██║░░██║  ██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██╔══██║██║╚████║██║░░██║  ██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
██║░░██║██║░╚███║██████╔╝  ███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░  ╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "./IFantomonTrainer.sol";
import "./IFantomonTrainerGraphics.sol";

contract FantomonMulticallV0 {
    uint256 BATCH_SIZE = 10;

    ERC721NFT trainer_;
    IFantomonTrainerGraphics graphics_;

    constructor (address _trainer, address _graphics) {
        trainer_  = ERC721NFT(_trainer);
        graphics_ = IFantomonTrainerGraphics(_graphics);
    }

    struct NFT {
        uint256 tokenId;
        string uri;
    }
    struct MultiViewNFT {
        uint256 tokenId;
        string svg;
        string art;
    }

    function _batchIdxs(address _user, uint256 _batch) internal view returns (uint256, uint256) {
        uint256 startTok = _batch*BATCH_SIZE;
        uint256 endTok   = (_batch+1)*BATCH_SIZE;
        uint256 bal      = trainer_.balanceOf(_user);
        if (bal < endTok) {
            endTok = bal;
        }
        return (startTok, endTok);
    }

    function tokensOfOwner(address _user, uint256 _batch) public view returns (uint256[] memory) {
        (uint256 startTok, uint256 endTok) = _batchIdxs(_user, _batch);

        uint256 idx;
        uint256 tok;
        uint256[] memory tokenIds = new uint256[](endTok-startTok);
        for (tok = startTok; tok < endTok; tok++) {
            tokenIds[idx] = trainer_.tokenOfOwnerByIndex(_user, tok);
            idx++;
        }
        return tokenIds;
    }

    function urisOfOwner(address _user, uint256 _batch) public view returns (string[] memory) {
        (uint256 startTok, uint256 endTok) = _batchIdxs(_user, _batch);

        uint256 idx;
        uint256 tok;
        string[] memory uris = new string[](endTok-startTok);
        for (tok = startTok; tok < endTok; tok++) {
            uint256 tokenId = trainer_.tokenOfOwnerByIndex(_user, tok);
            uris[idx] = trainer_.tokenURI(tokenId);
            idx++;
        }
        return uris;
    }

    function nftsOfOwner(address _user, uint256 _batch) public view returns (NFT[] memory) {
        (uint256 startTok, uint256 endTok) = _batchIdxs(_user, _batch);

        uint256 idx;
        uint256 tok;
        NFT[] memory nfts = new NFT[](endTok-startTok);
        for (tok = startTok; tok < endTok; tok++) {
            uint256 tokenId = trainer_.tokenOfOwnerByIndex(_user, tok);
            nfts[idx] = NFT(tokenId, trainer_.tokenURI(tokenId));
            idx++;
        }
        return nfts;
    }

    function nftsOfOwnerEmbeddable(address _user, bool _embed, uint256 _batch) public view returns (NFT[] memory) {
        (uint256 startTok, uint256 endTok) = _batchIdxs(_user, _batch);

        uint256 idx;
        uint256 tok;
        NFT[] memory nfts = new NFT[](endTok-startTok);
        for (tok = startTok; tok < endTok; tok++) {
            uint256 tokenId = trainer_.tokenOfOwnerByIndex(_user, tok);
            nfts[idx] = NFT(tokenId, graphics_.tokenURIEmbeddable(tokenId, IFantomonTrainer(address(trainer_)), _embed));
            idx++;
        }
        return nfts;
    }

    function multiViewNftsOfOwner(address _user, uint256 _batch) public view returns (MultiViewNFT[] memory) {
        (uint256 startTok, uint256 endTok) = _batchIdxs(_user, _batch);

        uint256 idx;
        uint256 tok;
        MultiViewNFT[] memory nfts = new MultiViewNFT[](endTok-startTok);
        for (tok = startTok; tok < endTok; tok++) {
            uint256 tokenId = trainer_.tokenOfOwnerByIndex(_user, tok);
            string memory svg = graphics_.tokenURIEmbeddable(tokenId, IFantomonTrainer(address(trainer_)), false);
            string memory art = graphics_.tokenURIEmbeddable(tokenId, IFantomonTrainer(address(trainer_)), true);
            nfts[idx] = MultiViewNFT(tokenId, svg, art);
            idx++;
        }
        return nfts;
    }
}
