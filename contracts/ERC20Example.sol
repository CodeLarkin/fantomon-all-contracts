// SPDX-License-Identifier: MIT
// ERC20Mintable - adapted from: OpenZeppelin Contracts v4.3.2 (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter role,
 * as well as the default admin role, which will let it grant minter role
 * to other accounts.
 */
contract ERC20Example is Context, AccessControlEnumerable, ERC20 {

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `MINTER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol, uint256 supply) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _mint(msg.sender, supply);
    }
}
