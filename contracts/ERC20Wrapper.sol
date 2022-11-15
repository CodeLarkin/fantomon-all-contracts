/*
██╗░░░░░░█████╗░██████╗░██╗░░██╗██╗███╗░░██╗
██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██║████╗░██║
██║░░░░░███████║██████╔╝█████═╝░██║██╔██╗██║
██║░░░░░██╔══██║██╔══██╗██╔═██╗░██║██║╚████║
███████╗██║░░██║██║░░██║██║░╚██╗██║██║░╚███║
╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝
*/
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Wrapper is ERC20 {
    ERC20 public token;

    /**
     * @dev sets values for
     * @param _token address of token for which this wrapper is for
     * @param _name a descriptive name mentioning market and outcome
     * @param _symbol symbol
     */
    constructor(
        ERC20 _token,
        string memory _name,
        string memory _symbol
    ) public ERC20(_name, _symbol) {
        token = _token;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.

     * Overrides function defined in ERC20.sol and just returns ``token``'s decimals
     * (wrapper token has same decimals as token being wrapped)
     */
    function decimals() public view override returns (uint8) {
        return token.decimals();
    }

    /**@dev A function that gets ERC20 ``token``s and mints a wrapped version
     * Requirements:
     *
     * - msg.sender needs to have approved this contract to spend at least ``_amount`` of ``token``
     * @param _amount amount of tokens to be wrapped
     */
    function wrapTokens(uint256 _amount) public {
        uint256 balBefore = token.balanceOf(address(this));
        token.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        uint256 balAfter = token.balanceOf(address(this));
        // performing this subtraction handles reflection tokens
        _mint(msg.sender, balAfter - balBefore);
    }

    /**@dev A function that burns wrapped token and gives back original ERC20s (``token``)
     * Requirements:
     *
     * - this contract must have allowance for caller's of at least `amount`.
     * @param _amount amount of tokens to be unwrapped
     */
    function unWrapTokens(uint256 _amount) public {
        _burn(msg.sender, _amount);

        token.transfer(
            msg.sender,
            _amount
        );
    }
}
