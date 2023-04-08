// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../src/Penguin.sol";
import "../Shared/Fixture.t.sol";

contract BuyTest is Fixture {
    uint256 public outputAmount = 10;
    uint256 public maxInputAmount;

    function setUp() public {
        uint256 baseTokenAmount = 100;
        uint256 fractionalTokenAmount = 30;

        deal(address(usd), address(this), baseTokenAmount, true);
        deal(address(pair), address(this), fractionalTokenAmount, true);

        usd.approve(address(pair), type(uint256).max);

        uint256 minLpTokenAmount = baseTokenAmount * fractionalTokenAmount;
        pair.add(baseTokenAmount, fractionalTokenAmount, minLpTokenAmount);

        maxInputAmount = pair.buyQuote(outputAmount);

        deal(address(usd), address(this), maxInputAmount, true);
    }

    function testItReturnsAmountIn() public {
        // arrange
        uint256 expectedInputAmount = maxInputAmount;

        // act
        uint256 inputAmount = pair.buy(outputAmount, maxInputAmount);

        // assert
        assertEq(
            inputAmount,
            expectedInputAmount,
            "Should have returned input amount"
        );
    }

    function testItTransfersBaseTokens() public {
        // arrange
        uint256 balanceBefore = usd.balanceOf(address(pair));
        uint256 thisBalanceBefore = usd.balanceOf(address(this));

        // act
        pair.buy(outputAmount, maxInputAmount);

        // assert
        assertEq(
            usd.balanceOf(address(pair)) - balanceBefore,
            maxInputAmount,
            "Should have transferred base tokens in"
        );
        assertEq(
            thisBalanceBefore - usd.balanceOf(address(this)),
            maxInputAmount,
            "Should have transferred base tokens out"
        );
    }

    function testItTransfersFractionalTokens() public {
        // arrange
        uint256 balanceBefore = pair.balanceOf(address(pair));
        uint256 thisBalanceBefore = pair.balanceOf(address(this));

        // act
        pair.buy(outputAmount, maxInputAmount);

        // assert
        assertEq(
            balanceBefore - pair.balanceOf(address(pair)),
            outputAmount,
            "Should have transferred fractional tokens in"
        );
        assertEq(
            pair.balanceOf(address(this)) - thisBalanceBefore,
            outputAmount,
            "Should have transferred fractional tokens out"
        );
    }

    function testItRevertsSlippageOnBuy() public {
        // arrange
        maxInputAmount -= 1; // subtract 1 to cause revert

        // act
        vm.expectRevert("Slippage: amount in is too large");
        pair.buy(outputAmount, maxInputAmount);
    }
}
