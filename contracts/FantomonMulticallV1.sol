/*
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./IFantomonTrainerInteractive.sol";
import "./IFantomonRegistry.sol";
import "./IFantomonStore.sol";
import "./IFantomonNaming.sol";
import "./IFantomonGraphics.sol";

import { FantomonLib } from "./FantomonLib.sol";

contract FantomonMulticallV1 {
    using FantomonLib for FantomonLib.Stats;

    IFantomonRegistry public registry_;

    constructor (IFantomonRegistry _registry) {
        registry_ = _registry;
    }

    struct Trainer {
        uint16 tokenId;
        uint8 kinship;
        uint8 flare;
        uint8 healing;
        uint8 courage;
        uint8 wins;
        uint8 losses;
        uint8 rarity;
        uint8 class;
        uint8 face;
        uint8 homeworld;
    }
    struct NFT {
        uint256 tokenId;
        string uri;
    }
    struct FmonWithScaled {
        uint256 tokenId;
        FantomonLib.Fmon fmon;
        FantomonLib.Stats scaledStats;
    }
    struct FmonNFT {
        uint256 tokenId;
        FantomonLib.Fmon fmon;
        FantomonLib.Stats scaledStats;
        string uri;
    }
    struct FmonImg {
        uint256 tokenId;
        FantomonLib.Fmon fmon;
        FantomonLib.Stats scaledStats;
        string name;
        string img;
    }

    function uris(uint256[] memory _tokenIds) public view returns (string[] memory) {
        ERC721 fmonNFT = registry_.fmonNFT_();
        string[] memory _uris = new string[](_tokenIds.length);
        for (uint256 t; t < _tokenIds.length; t++) {
            _uris[t] = fmonNFT.tokenURI(_tokenIds[t]);
        }
        return _uris;
    }

    function nfts(uint256[] memory _tokenIds) public view returns (NFT[] memory) {
        ERC721 fmonNFT = registry_.fmonNFT_();
        NFT[] memory _nfts = new NFT[](_tokenIds.length);
        for (uint256 t; t < _tokenIds.length; t++) {
            _nfts[t] = NFT(_tokenIds[t], fmonNFT.tokenURI(_tokenIds[t]));
        }
        return _nfts;
    }

    function fmons(uint256[] memory _tokenIds) public view returns (FantomonLib.Fmon[] memory) {
        IFantomonStore fstore = registry_.fstore_();
        FantomonLib.Fmon[] memory _fmons = new FantomonLib.Fmon[](_tokenIds.length);
        for (uint256 t; t < _tokenIds.length; t++) {
            _fmons[t] = fstore.fmon(_tokenIds[t]);
        }
        return _fmons;
    }

    function scaledStats(uint256[] memory _tokenIds) public view returns (FantomonLib.Stats[] memory) {
        IFantomonStore fstore = registry_.fstore_();
        FantomonLib.Stats[] memory _stats = new FantomonLib.Stats[](_tokenIds.length);
        for (uint256 t; t < _tokenIds.length; t++) {
            _stats[t] = fstore.getScaledStats(_tokenIds[t]);
        }
        return _stats;
    }

    function fmonsWithScaled(uint256[] memory _tokenIds) public view returns (FmonWithScaled[] memory) {
        IFantomonStore fstore = registry_.fstore_();
        FmonWithScaled[] memory _fmons = new FmonWithScaled[](_tokenIds.length);
        for (uint256 t; t < _tokenIds.length; t++) {
            _fmons[t] = FmonWithScaled(_tokenIds[t], fstore.fmon(_tokenIds[t]), fstore.getScaledStats(_tokenIds[t]));
        }
        return _fmons;
    }

    function fmonNFTs(uint256[] memory _tokenIds) public view returns (FmonNFT[] memory) {
        ERC721 fmonNFT = registry_.fmonNFT_();
        IFantomonStore fstore = registry_.fstore_();
        FmonNFT[] memory _nfts = new FmonNFT[](_tokenIds.length);
        for (uint256 t; t < _tokenIds.length; t++) {
            _nfts[t] = FmonNFT(_tokenIds[t], fstore.fmon(_tokenIds[t]), fstore.getScaledStats(_tokenIds[t]), fmonNFT.tokenURI(_tokenIds[t]));
        }
        return _nfts;
    }

    function fmonImgs(uint256[] memory _tokenIds) public view returns (FmonImg[] memory) {
        IFantomonGraphics fgraphics = registry_.fgraphics_();
        IFantomonStore fstore = registry_.fstore_();
        IFantomonNaming naming = IFantomonNaming(registry_.others_('naming'));
        FmonImg[] memory _imgs = new FmonImg[](_tokenIds.length);
        for (uint256 t; t < _tokenIds.length; t++) {
            _imgs[t] = FmonImg(_tokenIds[t], fstore.fmon(_tokenIds[t]), fstore.getScaledStats(_tokenIds[t]), naming.names_(_tokenIds[t]), fgraphics.imageURI(_tokenIds[t]));
        }
        return _imgs;
    }

    function trainer(uint256 _tokenId) public view returns (Trainer memory) {
        IFantomonTrainerInteractive ftNFT = registry_.ftNFT_();
        return Trainer(uint16(_tokenId),
                       uint8(ftNFT.getKinship(_tokenId)) , uint8(ftNFT.getFlare(_tokenId))   ,
                       uint8(ftNFT.getHealing(_tokenId)) , uint8(ftNFT.getCourage(_tokenId)) ,
                       uint8(ftNFT.getWins(_tokenId))    , uint8(ftNFT.getLosses(_tokenId))  ,
                       ftNFT.getRarity(_tokenId) , ftNFT.getClass(_tokenId)     ,
                       ftNFT.getFace(_tokenId)   , ftNFT.getHomeworld(_tokenId));
    }
}
