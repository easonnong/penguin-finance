// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../src/Pair.sol";
import "../Shared/Fixture.t.sol";

contract AddTest is Fixture {
    uint256 baseTokenAmount = 100;
    uint256 fractionalTokenAmount = 30;

    function setUp() public {
        deal(address(usd), address(this), baseTokenAmount, true);
        deal(address(pair), address(this), fractionalTokenAmount, true);

        usd.approve(address(pair), type(uint256).max);
    }

    function testItInitMintsLpTokensToSender() public {
        // arrange
        uint256 minLpTokenAmount = baseTokenAmount * fractionalTokenAmount;
        uint256 expectedLpTokenAmount = baseTokenAmount * fractionalTokenAmount;

        // act
        uint256 lpTokenAmount = pair.add(
            baseTokenAmount,
            fractionalTokenAmount,
            minLpTokenAmount
        );

        // assert
        assertEq(
            lpTokenAmount,
            expectedLpTokenAmount,
            "Should have returned correct lp token amount"
        );
        assertEq(
            lpToken.balanceOf(address(this)),
            expectedLpTokenAmount,
            "Should have minted lp tokens"
        );
        assertEq(
            lpToken.totalSupply(),
            expectedLpTokenAmount,
            "Should have increased lp supply"
        );
    }

    function testItTransfersBaseTokens() public {
        // arrange
        uint256 minLpTokenAmount = baseTokenAmount * fractionalTokenAmount;
        uint256 balanceBefore = usd.balanceOf(address(this));

        // act
        pair.add(baseTokenAmount, fractionalTokenAmount, minLpTokenAmount);

        // assert
        uint256 balanceAfter = usd.balanceOf(address(this));
        assertEq(
            balanceBefore - balanceAfter,
            baseTokenAmount,
            "Should transferred base tokens from sender"
        );
        assertEq(
            usd.balanceOf(address(pair)),
            baseTokenAmount,
            "Should have transferred base tokens to pair"
        );
    }

    function testItTransfersFractionalToken() public {
        // arrange
        uint256 minLpTokenAmount = baseTokenAmount * fractionalTokenAmount;
        uint256 balanceBefore = pair.balanceOf(address(this));

        // act
        pair.add(baseTokenAmount, fractionalTokenAmount, minLpTokenAmount);

        // assert
        assertEq(
            pair.balanceOf(address(pair)),
            fractionalTokenAmount,
            "Should have transferred fractional tokens to pair"
        );
        assertEq(
            balanceBefore - pair.balanceOf(address(this)),
            fractionalTokenAmount,
            "Should transferred fractional tokens from sender"
        );
    }

    function testItRevertsSlippageOnInitMint() public {
        // arrange
        uint256 minLpTokenAmount = (baseTokenAmount * fractionalTokenAmount) +
            1; //increase 1 to cause revert

        // act
        vm.expectRevert("Slippage: Insufficient lp token output amount");
        pair.add(baseTokenAmount, fractionalTokenAmount, minLpTokenAmount);
    }

    function testItMintsLpTokensAfterInit() public {
        // arrange
        uint256 minLpTokenAmount = baseTokenAmount * fractionalTokenAmount;
        pair.add(baseTokenAmount, fractionalTokenAmount, minLpTokenAmount); // initial add
        uint256 lpTokenSupplyBefore = lpToken.totalSupply();

        uint256 expectedLpTokenAmount = baseTokenAmount *
            fractionalTokenAmount *
            17;
        minLpTokenAmount = expectedLpTokenAmount;
        baseTokenAmount = baseTokenAmount * 17;
        fractionalTokenAmount = fractionalTokenAmount * 17;
        deal(address(usd), hacker, baseTokenAmount, true);
        deal(address(pair), hacker, fractionalTokenAmount, true);

        // act
        vm.startPrank(hacker);
        usd.approve(address(pair), type(uint256).max);
        uint256 lpTokenAmount = pair.add(
            baseTokenAmount,
            fractionalTokenAmount,
            minLpTokenAmount
        );
        vm.stopPrank();

        // assert
        assertEq(
            lpTokenAmount,
            expectedLpTokenAmount,
            "Should have returned lp token amount"
        );
        assertEq(
            lpToken.balanceOf(hacker),
            expectedLpTokenAmount,
            "Should have minted lp tokens"
        );
        assertEq(
            lpToken.totalSupply() - lpTokenSupplyBefore,
            expectedLpTokenAmount,
            "Should have increased lp supply"
        );
    }

    function testItRevertsSlippageAfterInitMint() public {
        // arrange
        uint256 minLpTokenAmount = baseTokenAmount * fractionalTokenAmount;
        pair.add(baseTokenAmount, fractionalTokenAmount, minLpTokenAmount); // initial add

        minLpTokenAmount = (baseTokenAmount * fractionalTokenAmount * 17) + 1; // add 1 to casue a revert
        baseTokenAmount = baseTokenAmount * 17;
        fractionalTokenAmount = fractionalTokenAmount * 17;

        // act
        vm.expectRevert("Slippage: Insufficient lp token output amount");

        pair.add(baseTokenAmount, fractionalTokenAmount, minLpTokenAmount);
    }
}