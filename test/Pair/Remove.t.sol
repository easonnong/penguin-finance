// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../Shared/Fixture.t.sol";
import "../../src/Penguin.sol";

contract RemoveTest is Fixture {
    uint256 public totalBaseTokenAmount = 100;
    uint256 public totalFractionalTokenAmount = 30;
    uint256 public totalLpTokenAmount;

    function setUp() public {
        deal(address(usd), address(this), totalBaseTokenAmount, true);
        deal(address(pair), address(this), totalFractionalTokenAmount, true);
        deal(address(ethPair), address(this), totalFractionalTokenAmount, true);

        usd.approve(address(pair), type(uint256).max);

        uint256 minLpTokenAmount = Math.sqrt(
            totalBaseTokenAmount * totalFractionalTokenAmount
        );
        totalLpTokenAmount = pair.add(
            totalBaseTokenAmount,
            totalFractionalTokenAmount,
            minLpTokenAmount
        );
        ethPair.add{value: totalBaseTokenAmount}(
            totalBaseTokenAmount,
            totalFractionalTokenAmount,
            minLpTokenAmount
        );
    }

    function testItReturnsBaseTokenAmountAndFractionalTokenAmount() public {
        // arrange
        uint256 lpTokenAmount = totalLpTokenAmount / 2;
        uint256 expectedBaseTokenAmount = totalBaseTokenAmount / 2;
        uint256 expectedFractionalTokenAmount = totalFractionalTokenAmount / 2;

        // act
        (uint256 baseTokenAmount, uint256 fractionalTokenAmount) = pair.remove(
            lpTokenAmount,
            expectedBaseTokenAmount,
            expectedFractionalTokenAmount
        );

        // assert
        assertEq(
            baseTokenAmount,
            expectedBaseTokenAmount,
            "Should have returned correct base token amount"
        );
        assertEq(
            fractionalTokenAmount,
            expectedFractionalTokenAmount,
            "Should have returned correct fractional token amount"
        );
    }

    function testItBurnsLpTokens() public {
        // arrange
        uint256 lpTokenAmount = totalLpTokenAmount / 2;
        uint256 minBaseTokenOutputAmount = totalBaseTokenAmount / 2;
        uint256 minFractionalTokenOutputAmount = totalFractionalTokenAmount / 2;
        uint256 balanceBefore = lpToken.balanceOf(address(this));
        uint256 totalSupplyBefore = lpToken.totalSupply();

        // act
        pair.remove(
            lpTokenAmount,
            minBaseTokenOutputAmount,
            minFractionalTokenOutputAmount
        );

        // assert
        assertEq(
            balanceBefore - lpToken.balanceOf(address(this)),
            lpTokenAmount,
            "Should have burned lp tokens from sender"
        );
        assertEq(
            totalSupplyBefore - lpToken.totalSupply(),
            lpTokenAmount,
            "Should have burned lp tokens"
        );
    }

    function testItTransfersBaseTokens() public {
        // arrange
        uint256 lpTokenAmount = totalLpTokenAmount / 2;
        uint256 minBaseTokenOutputAmount = totalBaseTokenAmount / 2;
        uint256 minFractionalTokenOutputAmount = totalFractionalTokenAmount / 2;
        uint256 thisBalanceBefore = usd.balanceOf(address(this));
        uint256 balanceBefore = usd.balanceOf(address(pair));

        // act
        pair.remove(
            lpTokenAmount,
            minBaseTokenOutputAmount,
            minFractionalTokenOutputAmount
        );

        // assert
        assertEq(
            usd.balanceOf(address(this)) - thisBalanceBefore,
            minBaseTokenOutputAmount,
            "Should have transferred base tokens to sender"
        );

        assertEq(
            balanceBefore - usd.balanceOf(address(pair)),
            minBaseTokenOutputAmount,
            "Should have transferred base tokens from pair"
        );
    }

    function testItTransfersFractionalTokens() public {
        // arrange
        uint256 lpTokenAmount = totalLpTokenAmount / 2;
        uint256 minBaseTokenOutputAmount = totalBaseTokenAmount / 2;
        uint256 minFractionalTokenOutputAmount = totalFractionalTokenAmount / 2;
        uint256 thisBalanceBefore = pair.balanceOf(address(this));
        uint256 balanceBefore = pair.balanceOf(address(pair));

        // act
        pair.remove(
            lpTokenAmount,
            minBaseTokenOutputAmount,
            minFractionalTokenOutputAmount
        );

        // assert
        assertEq(
            pair.balanceOf(address(this)) - thisBalanceBefore,
            minFractionalTokenOutputAmount,
            "Should have transferred fractionall tokens to sender"
        );

        assertEq(
            balanceBefore - pair.balanceOf(address(pair)),
            minFractionalTokenOutputAmount,
            "Should have transferred fractional tokens from pair"
        );
    }

    function testItRevertsFractionalTokenSlippage() public {
        // arrange
        uint256 lpTokenAmount = totalLpTokenAmount / 2;
        uint256 minBaseTokenOutputAmount = totalBaseTokenAmount / 2;
        uint256 minFractionalTokenOutputAmount = totalFractionalTokenAmount /
            2 +
            1; // add 1 to cause revert

        // act
        vm.expectRevert("Slippage: fractional token amount out");
        pair.remove(
            lpTokenAmount,
            minBaseTokenOutputAmount,
            minFractionalTokenOutputAmount
        );
    }

    function testItRevertsBaseTokenSlippage() public {
        // arrange
        uint256 lpTokenAmount = totalLpTokenAmount / 2;
        uint256 minBaseTokenOutputAmount = totalBaseTokenAmount / 2 + 1; // add 1 to cause revert
        uint256 minFractionalTokenOutputAmount = totalFractionalTokenAmount / 2;

        // act
        vm.expectRevert("Slippage: base token amount out");
        pair.remove(
            lpTokenAmount,
            minBaseTokenOutputAmount,
            minFractionalTokenOutputAmount
        );
    }

    function testItTransfersEther() public {
        // arrange
        uint256 lpTokenAmount = totalLpTokenAmount / 2;
        uint256 minBaseTokenOutputAmount = totalBaseTokenAmount / 2;
        uint256 minFractionalTokenOutputAmount = totalFractionalTokenAmount / 2;
        uint256 thisBalanceBefore = address(this).balance;
        uint256 balanceBefore = address(ethPair).balance;

        // act
        ethPair.remove(
            lpTokenAmount,
            minBaseTokenOutputAmount,
            minFractionalTokenOutputAmount
        );

        // assert
        assertEq(
            address(this).balance - thisBalanceBefore,
            minBaseTokenOutputAmount,
            "Should have transferred ether to sender"
        );

        assertEq(
            balanceBefore - address(ethPair).balance,
            minBaseTokenOutputAmount,
            "Should have transferred ether from pair"
        );
    }
}
