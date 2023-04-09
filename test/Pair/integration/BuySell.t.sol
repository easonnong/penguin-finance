// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../Shared/Fixture.t.sol";
import "../../../src/Penguin.sol";

contract BuySellTest is Fixture {
    function setUp() public {
        uint256 baseTokenAmount = 100e18;
        uint256 fractionalTokenAmount = 100e18;

        deal(address(usd), address(this), baseTokenAmount, true);
        deal(address(pair), address(this), fractionalTokenAmount, true);

        usd.approve(address(pair), type(uint256).max);

        uint256 minLpTokenAmount = Math.sqrt(
            baseTokenAmount * fractionalTokenAmount
        );
        pair.add(baseTokenAmount, fractionalTokenAmount, minLpTokenAmount);

        deal(address(ethPair), address(this), fractionalTokenAmount, true);
        ethPair.add{value: baseTokenAmount}(
            baseTokenAmount,
            fractionalTokenAmount,
            minLpTokenAmount
        );
    }

    function testItBuysSellsEqualAmounts(uint256 outputAmount) public {
        outputAmount = bound(
            outputAmount,
            1e2,
            pair.fractionalTokenReserves() - 1e18
        );
        uint256 maxInputAmount = (outputAmount *
            pair.baseTokenReserves() *
            1000) / ((pair.fractionalTokenReserves() - outputAmount) * 997);
        deal(address(usd), address(this), maxInputAmount, true);

        // act
        pair.buy(outputAmount, maxInputAmount);
        pair.sell(outputAmount, 0);

        // assert
        assertApproxEqAbs(
            usd.balanceOf(address(this)),
            maxInputAmount,
            maxInputAmount - (((maxInputAmount * 997) / 1000) * 997) / 1000, // allow margin of error for approx. fee amount
            "Should have bought and sold equal amounts of assets"
        );

        assertGt(
            maxInputAmount,
            usd.balanceOf(address(this)),
            "Should have less usd than starting with because of fees"
        );
    }
}
