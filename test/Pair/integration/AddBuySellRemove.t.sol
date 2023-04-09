// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../shared/Fixture.t.sol";
import "../../../src/Penguin.sol";

contract AddBuySellRemoveTest is Fixture {
    function testItAddsBuysSellsRemovesCorrectAmount(
        uint256 addBaseTokenAmount,
        uint256 addFractionalTokenAmount,
        uint256 buyTokenAmount
    ) public {
        addBaseTokenAmount = bound(addBaseTokenAmount, 100, type(uint96).max);
        addFractionalTokenAmount = bound(
            addFractionalTokenAmount,
            2,
            10_000_000 * 1e18
        );
        buyTokenAmount = bound(buyTokenAmount, 1, addFractionalTokenAmount - 1);

        // add liquidity
        deal(address(usd), address(this), addBaseTokenAmount, true);
        deal(address(pair), address(this), addFractionalTokenAmount, true);
        uint256 lpTokenAmount = Math.sqrt(
            addBaseTokenAmount * addFractionalTokenAmount
        );
        usd.approve(address(pair), type(uint256).max);
        pair.add(addBaseTokenAmount, addFractionalTokenAmount, lpTokenAmount);

        // buy some amount
        uint256 baseTokenBuyAmount = pair.buyQuote(buyTokenAmount);
        deal(address(usd), address(this), baseTokenBuyAmount, true);
        pair.buy(buyTokenAmount, baseTokenBuyAmount);

        // remove some fraction of liquidity
        uint256 removeLpTokenAmount = lpTokenAmount / 10;
        uint256 expectedBaseTokenAmount = (pair.baseTokenReserves() *
            removeLpTokenAmount) / lpToken.totalSupply();
        uint256 expectedFractionalTokenAmount = (pair
            .fractionalTokenReserves() * removeLpTokenAmount) /
            lpToken.totalSupply();
        (
            uint256 baseTokenOutputAmount,
            uint256 fractionalTokenOutputAmount
        ) = pair.remove(removeLpTokenAmount, 0, 0);

        assertEq(
            baseTokenOutputAmount,
            expectedBaseTokenAmount,
            "Should have removed correct base token amount"
        );
        assertEq(
            fractionalTokenOutputAmount,
            expectedFractionalTokenAmount,
            "Should have removed correct fractional token amount"
        );
    }
}
