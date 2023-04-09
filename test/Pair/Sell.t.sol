// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../Shared/Fixture.t.sol";
import "../../src/Penguin.sol";

contract SellTest is Fixture {
    uint256 public inputAmount = 10;
    uint256 public minOutputAmount;

    function setUp() public {
        uint256 baseTokenAmount = 100;
        uint256 fractionalTokenAmount = 30;

        deal(address(usd), address(this), baseTokenAmount, true);
        deal(address(pair), address(this), fractionalTokenAmount, true);

        usd.approve(address(pair), type(uint256).max);

        uint256 minLpTokenAmount = Math.sqrt(
            baseTokenAmount * fractionalTokenAmount
        );
        pair.add(baseTokenAmount, fractionalTokenAmount, minLpTokenAmount);

        minOutputAmount = pair.sellQuote(inputAmount);

        deal(address(pair), address(this), inputAmount, true);
        deal(address(ethPair), address(this), fractionalTokenAmount, true);
        ethPair.add{value: baseTokenAmount}(
            baseTokenAmount,
            fractionalTokenAmount,
            minLpTokenAmount
        );
        deal(address(ethPair), address(this), inputAmount, true);
    }

    function testItReturnsOutputAmount() public {
        // arrange
        uint256 expectedOutputAmount = minOutputAmount;

        // act
        uint256 outputAmount = pair.sell(inputAmount, expectedOutputAmount);

        // assert
        assertEq(
            outputAmount,
            expectedOutputAmount,
            "Should have returned output amount"
        );
    }

    function testItTransfersBaseTokens() public {
        // arrange
        uint256 balanceBefore = usd.balanceOf(address(pair));
        uint256 thisBalanceBefore = usd.balanceOf(address(this));

        // act
        pair.sell(inputAmount, minOutputAmount);

        // assert
        assertEq(
            balanceBefore - usd.balanceOf(address(pair)),
            minOutputAmount,
            "Should have transferred base tokens from pair"
        );
        assertEq(
            usd.balanceOf(address(this)) - thisBalanceBefore,
            minOutputAmount,
            "Should have transferred base tokens to sender"
        );
    }

    function testItTransfersFractionalTokens() public {
        // arrange
        uint256 balanceBefore = pair.balanceOf(address(pair));
        uint256 thisBalanceBefore = pair.balanceOf(address(this));

        // act
        pair.sell(inputAmount, minOutputAmount);

        // assert
        assertEq(
            thisBalanceBefore - pair.balanceOf(address(this)),
            inputAmount,
            "Should have transferred fractional tokens from sender"
        );
        assertEq(
            pair.balanceOf(address(pair)) - balanceBefore,
            inputAmount,
            "Should have transferred fractional tokens to pair"
        );
    }

    function testItRevertsSlippageOnSell() public {
        // arrange
        minOutputAmount += 1; // add 1 to cause revert

        // act
        vm.expectRevert("Slippage: amount out");
        pair.sell(inputAmount, minOutputAmount);
    }

    function testItTransfersEther() public {
        // arrange
        uint256 balanceBefore = address(ethPair).balance;
        uint256 thisBalanceBefore = address(this).balance;

        // act
        ethPair.sell(inputAmount, minOutputAmount);

        // assert
        assertEq(
            balanceBefore - address(ethPair).balance,
            minOutputAmount,
            "Should have transferred ether from pair"
        );
        assertEq(
            address(this).balance - thisBalanceBefore,
            minOutputAmount,
            "Should have transferred ether to sender"
        );
    }
}
