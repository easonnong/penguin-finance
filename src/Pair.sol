// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/tokens/ERC20.sol";
import "openzeppelin/utils/math/Math.sol";

import "./LpToken.sol";

contract Pair is ERC20 {
    uint256 public constant ONE = 1e18;

    address public immutable nft; // address of the NFT
    address public immutable baseToken; // address of the base token
    address public immutable lpToken;

    constructor(address _nft, address _baseToken)
        ERC20("Fractional token", "FT", 18)
    {
        nft = _nft;
        baseToken = _baseToken;

        lpToken = address(new LpToken("LP token", "LPT", 18));
    }

    // ====================== //
    // ===== Core logic ===== //
    // ====================== //

    /**
     * @dev Adds liquidity to the pool
     * @param baseTokenAmount The amount of base token to add
     * @param fractionalTokenAmount The amount of fractional token to add
     * @param minLpTokenAmount The minimum amount of LP token to receive
     * @return The amount of LP tokens minted
     */
    function add(
        uint256 baseTokenAmount,
        uint256 fractionalTokenAmount,
        uint256 minLpTokenAmount
    ) public returns (uint256) {
        uint256 lpTokenSupply = ERC20(lpToken).totalSupply();
        uint256 lpTokenAmount;

        if (lpTokenSupply > 0) {
            uint256 baseTokenShare = (baseTokenAmount * lpTokenSupply) /
                baseTokenReserves();
            uint256 fractionalTokenShare = (fractionalTokenAmount *
                lpTokenSupply) / fractionalTokenReserves();

            lpTokenAmount = Math.min(baseTokenShare, fractionalTokenShare);
        } else {
            // if there is no liquidity then init
            lpTokenAmount = baseTokenAmount * fractionalTokenAmount;
        }

        // check that the amount of lp tokens outputted is greater than the min amount
        require(
            lpTokenAmount >= minLpTokenAmount,
            "Slippage: Insufficient lp token output amount"
        );

        // transfer tokens in
        ERC20(baseToken).transferFrom(
            msg.sender,
            address(this),
            baseTokenAmount
        );
        _transferFrom(msg.sender, address(this), fractionalTokenAmount);

        // mint lp tokens to sender
        LpToken(lpToken).mint(msg.sender, lpTokenAmount);

        return lpTokenAmount;
    }

    /**
     * @dev Buys fractional tokens with base tokens
     * @param outputAmount The amount of fractional tokens to buy
     * @param maxInputAmount The maximum amount of base tokens to spend
     * @return The amount of base tokens spent
     */
    function buy(uint256 outputAmount, uint256 maxInputAmount)
        public
        returns (uint256)
    {
        // x * y = k
        // Calculate the required amount of base tokens to buy the output amount of fractional tokens
        // (baseTokenReserves + amountIn)*(fractionalTokenReserves - outputAmount) = baseTokenReserves * fractionalTokenReserves
        // baseTokenReserves + amountIn = （baseTokenReserves * fractionalTokenReserves）/ (fractionalTokenReserves - outputAmount)
        // amountIn = （baseTokenReserves * fractionalTokenReserves - (baseTokenReserves*fractionalTokenReserves - baseTokenReserves*outputAmount)）/ (fractionalTokenReserves - outputAmount)
        // amountIn = (baseTokenReserves*outputAmount) / (fractionalTokenReserves - outputAmount)
        uint256 amountIn = (outputAmount * baseTokenReserves()) /
            (fractionalTokenReserves() - outputAmount);

        // check that the required amount of base tokens is less than the max amount
        require(amountIn <= maxInputAmount, "Slippage: amount in is too large");

        // transfer fractional tokens to sender
        transfer(msg.sender, outputAmount);

        // transfer base token in
        ERC20(baseToken).transferFrom(msg.sender, address(this), amountIn);

        return amountIn;
    }

    // ========================== //
    // ===== Internal utils ===== //
    // ========================== //

    function _transferFrom(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        balanceOf[from] -= amount;

        // cannot overflow because the sum of all user
        // balances cannot exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    // =================== //
    // ===== Getters ===== //
    // =================== //

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
