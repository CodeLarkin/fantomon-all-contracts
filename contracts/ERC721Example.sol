// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract ERC721Example is ERC721 {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    constructor(string memory _name, string memory _ticker) ERC721(_name, _ticker) {}

    function mint() external {
        _tokenIds.increment();
        _safeMint(msg.sender, _tokenIds.current());
    }
}
