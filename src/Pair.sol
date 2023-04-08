// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/tokens/ERC20.sol";
import "openzeppelin/utils/math/Math.sol";

import "./LpToken.sol";

contract Pair is ERC20 {
    uint256 constant ONE = 1e18;

    address immutable nft; // address of the NFT
    address immutable baseToken; // address of the base token
    address immutable lpToken;

    constructor(address _nft, address _baseToken)
        ERC20("Fractional token", "FT", 18)
    {
        nft = _nft;
        baseToken = _baseToken;

        lpToken = address(new LpToken("LP token", "LPT", 18));
    }

    /**
     * @dev Adds liquidity to the pool
     * @param baseTokenAmount The amount of base token to add
     * @param fractionalTokenAmount The amount of fractional token to add
     * @param minLpTokenAmount The minimum amount of LP token to receive
     */
    function add(
        uint256 baseTokenAmount,
        uint256 fractionalTokenAmount,
        uint256 minLpTokenAmount
    ) public {
        uint256 lpTokenSupply = ERC20(lpToken).totalSupply();
        uint256 baseTokenShare = (baseTokenAmount * lpTokenSupply) /
            baseTokenReserves();
        uint256 fractionalTokenShare = (fractionalTokenAmount * lpTokenSupply) /
            fractionalTokenReserves();

        uint256 lpTokenAmount = Math.min(baseTokenShare, fractionalTokenShare);
        require(
            lpTokenAmount >= minLpTokenAmount,
            "Slippage: Insufficient LP token output amount"
        );

        ERC20(baseToken).transferFrom(
            msg.sender,
            address(this),
            baseTokenAmount
        );
        transferFrom(msg.sender, address(this), fractionalTokenAmount);

        LpToken(lpToken).mint(msg.sender, lpTokenAmount);
    }

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

    /**
     * @dev Returns the base token reserves
     * @return The base token reserves
     */
    function baseTokenReserves() public view returns (uint256) {
        return ERC20(baseToken).balanceOf(address(this));
    }

    /**
     * @dev Returns the fractional token reserves
     * @return The fractional token reserves
     */
    function fractionalTokenReserves() public view returns (uint256) {
        return balanceOf[address(this)];
    }
}
