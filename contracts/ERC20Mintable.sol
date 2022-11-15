// SPDX-License-Identifier: MIT
// ERC20Mintable - adapted from: OpenZeppelin Contracts v4.3.2 (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
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
contract ERC20Mintable is Context, AccessControlEnumerable, ERC20Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public maxSupply;
    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `MINTER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory _name, string memory _symbol, uint256 _maxSupply) ERC20(_name, _symbol) {
        maxSupply = _maxSupply;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20Mintable: must have minter role to mint");
        // enforce supply cap
        uint256 initialSupply = totalSupply();
        if (initialSupply + amount > maxSupply) {
            amount = maxSupply - initialSupply;
        }
        _mint(to, amount);
    }
}
