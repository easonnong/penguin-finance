// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/tokens/ERC20.sol";

contract Pair {
    uint256 constant ONE = 1e18;
    address immutable nft; // address of the NFT
    address immutable baseToken; // address of the base token

    constructor(address _nft, address _baseToken) {
        nft = _nft;
        baseToken = _baseToken;
    }

    /**
     * @dev Adds liquidity to the pool
     * @param baseTokenAmount The amount of base token to add
     * @param fractionalTokenAmount The amount of fractional token to add
     * @param minBaseTokenOutputAmount The minimum amount of base token to receive
     * @param minFractionalTokenOutputAmount The minimum amount of fractional token to receive
     */
    function add(
        uint256 baseTokenAmount,
        uint256 fractionalTokenAmount,
        uint256 minBaseTokenOutputAmount,
        uint256 minFractionalTokenOutputAmount
    ) public {}

    /**
     * @dev Returns the current price of the pair
     * @return The current price of the pair
     */
    function price() public view returns (uint256) {
        uint256 baseTokenBalance = ERC20(baseToken).balanceOf(address(this)); // balance of the base token
        uint256 fractionalTokenBalance = ERC20(address(this)).balanceOf(
            address(this)
        ); // balance of the fractional token

        return (baseTokenBalance * ONE) / fractionalTokenBalance; // return the current price
    }
}
