// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/tokens/ERC20.sol";
import "solmate/tokens/ERC721.sol";
import "openzeppelin/utils/math/Math.sol";

import "./LpToken.sol";

contract Pair is ERC20, ERC721TokenReceiver {
    uint256 public constant ONE = 1e18;

    address public immutable nft; // address of the NFT
    address public immutable baseToken; // address of the base token
    address public immutable lpToken;

    constructor(
        address _nft,
        address _baseToken
    ) ERC20("Fractional token", "FT", 18) {
        nft = _nft;
        baseToken = _baseToken;

        lpToken = address(new LpToken("LP token", "LPT", 18));
    }

    // ====================== //
    // ===== AMM logic ===== //
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
            "Slippage: lp token amount out"
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
    function buy(
        uint256 outputAmount,
        uint256 maxInputAmount
    ) public returns (uint256) {
        // x * y = k
        // Calculate the required amount of base tokens to buy the output amount of fractional tokens
        // (baseTokenReserves + inputAmount)*(fractionalTokenReserves - outputAmount) = baseTokenReserves * fractionalTokenReserves
        // baseTokenReserves + inputAmount = （baseTokenReserves * fractionalTokenReserves）/ (fractionalTokenReserves - outputAmount)
        // inputAmount = （baseTokenReserves * fractionalTokenReserves - (baseTokenReserves*fractionalTokenReserves - baseTokenReserves*outputAmount)）/ (fractionalTokenReserves - outputAmount)
        // inputAmount = (baseTokenReserves*outputAmount) / (fractionalTokenReserves - outputAmount)
        uint256 inputAmount = (outputAmount * baseTokenReserves()) /
            (fractionalTokenReserves() - outputAmount);

        // check that the required amount of base tokens is less than the max amount
        require(inputAmount <= maxInputAmount, "Slippage: amount in");

        // transfer fractional tokens to sender
        _transferFrom(address(this), msg.sender, outputAmount);

        // transfer base token in
        ERC20(baseToken).transferFrom(msg.sender, address(this), inputAmount);

        return inputAmount;
    }

    function sell(
        uint256 inputAmount, // fractionalTokenAmount
        uint256 minOutputAmount
    ) public returns (uint256) {
        // (baseTokenReserves - outputAmount)*(fractionalTokenReserves + inputAmount) = baseTokenReserves * fractionalTokenReserves
        // baseTokenReserves - outputAmount = (baseTokenReserves * fractionalTokenReserves) / (fractionalTokenReserves + inputAmount)
        // outputAmount = (baseTokenReserves*fractionalTokenReserves + baseTokenReserves*inputAmount - baseTokenReserves * fractionalTokenReserves) / (fractionalTokenReserves + inputAmount)
        // outputAmount = (baseTokenReserves*inputAmount) / (fractionalTokenReserves + inputAmount)
        //@audit outputAmoount issuse
        uint256 outputAmount = (baseTokenReserves() * inputAmount) /
            (fractionalTokenReserves() + inputAmount);

        // check that the outputted amount of fractional tokens is greater than the min amount
        require(outputAmount >= minOutputAmount, "Slippage: amount out");

        // transfer fractional tokens from sender
        _transferFrom(msg.sender, address(this), inputAmount);

        // transfer base tokens out
        ERC20(baseToken).transfer(msg.sender, outputAmount);

        return outputAmount;
    }

    function remove(
        uint256 lpTokenAmount,
        uint256 minBaseTokenOutputAmount,
        uint256 minFractionalTokenOutputAmount
    ) public returns (uint256, uint256) {
        // calculate the output amounts
        uint256 lpTokenSupply = ERC20(lpToken).totalSupply();
        uint256 baseTokenOutputAmount = (baseTokenReserves() * lpTokenAmount) /
            lpTokenSupply;
        uint256 fractionalTokenOutputAmount = (fractionalTokenReserves() *
            lpTokenAmount) / lpTokenSupply;

        // ~~~~~~ Checks ~~~~~~ //

        // check that the base token output amount is greater than the min amount
        require(
            baseTokenOutputAmount >= minBaseTokenOutputAmount,
            "Slippage: base token amount out"
        );
        // check that the fractional token output amount is greater than the min amount
        require(
            fractionalTokenOutputAmount >= minFractionalTokenOutputAmount,
            "Slippage: fractional token amount out"
        );

        // ~~~~~~ Effects ~~~~~~ //

        // transfer fractional tokens to sender
        _transferFrom(address(this), msg.sender, fractionalTokenOutputAmount);

        // ~~~~~~ Interactions ~~~~~~ //

        // transfer base tokens to sender
        ERC20(baseToken).transfer(msg.sender, baseTokenOutputAmount);

        // burn lp tokens from sender
        LpToken(lpToken).burn(msg.sender, lpTokenAmount);

        return (baseTokenOutputAmount, fractionalTokenOutputAmount);
    }

    // ========================= //
    // ===== NFT AMM logic ===== //
    // ========================= //

    function nftAdd(
        uint256 baseTokenAmount,
        uint256[] calldata tokenIds,
        uint256 minLpTokenAmount
    ) public returns (uint256) {
        uint256 fractionalTokenAmount = wrap(tokenIds);
        uint256 lpTokenAmount = add(
            baseTokenAmount,
            fractionalTokenAmount,
            minLpTokenAmount
        );

        return lpTokenAmount;
    }

    function nftRemove(
        uint256 lpTokenAmount,
        uint256 minBaseTokenOutputAmount,
        uint256[] calldata tokenIds
    ) public returns (uint256, uint256) {
        (
            uint256 baseTokenOutputAmount,
            uint256 fractionalTokenOutputAmount
        ) = remove(
                lpTokenAmount,
                minBaseTokenOutputAmount,
                tokenIds.length * 1e18
            );
        unwrap(tokenIds);

        return (baseTokenOutputAmount, fractionalTokenOutputAmount);
    }

    function nftBuy(
        uint256[] calldata tokenIds,
        uint256 maxInputAmount
    ) public returns (uint256) {
        uint256 inputAmount = buy(tokenIds.length * 1e18, maxInputAmount);
        unwrap(tokenIds);

        return inputAmount;
    }

    function nftSell(
        uint256[] calldata tokenIds,
        uint256 minOutputAmount
    ) public returns (uint256) {
        uint256 inputAmount = wrap(tokenIds); // fractionalTokenAmount
        uint256 outputAmount = sell(inputAmount, minOutputAmount);

        return outputAmount;
    }

    // ====================== //
    // ===== Wrap logic ===== //
    // ====================== //

    function wrap(uint256[] calldata tokenIds) public returns (uint256) {
        // ~~~~~~ Effects ~~~~~~ //
        uint256 fractionalTokenAmount = tokenIds.length * ONE;

        // mint fractional tokens to sender
        _mint(msg.sender, fractionalTokenAmount);

        // ~~~~~~ Interactions ~~~~~~ //

        // transfer nfts from sender
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ERC721(nft).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
        }

        return fractionalTokenAmount;
    }

    function unwrap(uint256[] calldata tokenIds) public returns (uint256) {
        // ~~~~~~ Effects ~~~~~~ //
        uint256 fractionalTokenAmount = tokenIds.length * ONE;

        // burn fractional tokens from sender
        _burn(msg.sender, fractionalTokenAmount);

        // ~~~~~~ Interactions ~~~~~~ //

        // transfer nfts to sender
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ERC721(nft).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );
        }

        return fractionalTokenAmount;
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

    /**
     * @dev Calculates the amount of base tokens required to buy a given amount of fractional tokens
     * @param outputAmount The amount of fractional tokens to buy
     * @return The amount of base tokens required
     */
    function buyQuote(uint256 outputAmount) public view returns (uint256) {
        return
            (outputAmount * baseTokenReserves()) /
            (fractionalTokenReserves() - outputAmount);
    }
}
