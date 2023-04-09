// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC20.sol";

contract LpToken is Owned, ERC20 {
    constructor(
        string memory pairSymbol
    )
        Owned(msg.sender)
        ERC20(
            string.concat(pairSymbol, " LP token"),
            string.concat("LP-", pairSymbol),
            18
        )
    {}

    /**
     * @dev Mints new tokens and sends them to the specified address.
     * Can only be called by the contract owner.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Burns tokens from the specified address.
     * Can only be called by the contract owner.
     */
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}
