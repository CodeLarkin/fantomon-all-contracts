// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * @dev Interface for a Fantomon Location contract
 */
interface IFantomon {
    function interact(uint256 _trainer, uint256 _fantomon, uint256[] calldata _args) external;
}
