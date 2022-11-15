// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IFantomonRoyalties {
    function larkin_() external returns (address payable);
    function water_() external returns (address payable);
    function royaltyShares_() external returns (uint256 _shares);
    function  set25Receiver(uint256 _tokenId, address _receiver) external;
    function  set50Receiver(uint256 _tokenId, address _receiver) external;
    function  set75Receiver(uint256 _tokenId, address _receiver) external;
    function set100Receiver(uint256 _tokenId, address _receiver) external;
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address _receiver, uint256 _royaltyAmount);
    receive() external payable;
}
