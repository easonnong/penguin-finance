// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../shared/Fixture.t.sol";
import "../../src/Penguin.sol";
import "solmate/tokens/ERC721.sol";

contract NftBuyTest is Fixture, ERC721TokenReceiver {
    uint256 public outputAmount;
    uint256 public maxInputAmount;
    uint256[] public tokenIds;

    function setUp() public {
        for (uint256 i = 0; i < 5; i++) {
            bayc.mint(address(this), i);
            tokenIds.push(i);
        }

        bayc.setApprovalForAll(address(pair), true);
        usd.approve(address(pair), type(uint256).max);

        uint256 baseTokenAmount = 3.15e18;
        uint256 minLpTokenAmount = baseTokenAmount * tokenIds.length * 1e18;
        deal(address(usd), address(this), baseTokenAmount, true);
        pair.nftAdd(baseTokenAmount, tokenIds, minLpTokenAmount);

        tokenIds.pop();
        tokenIds.pop();
        outputAmount = tokenIds.length * 1e18;
        maxInputAmount =
            (outputAmount * pair.baseTokenReserves()) /
            (pair.fractionalTokenReserves() - outputAmount);
        deal(address(usd), address(this), maxInputAmount, true);
    }

    function testItReturnsInputAmount() public {
        // arrange
        uint256 expectedInputAmount = maxInputAmount;

        // act
        uint256 inputAmount = pair.nftBuy(tokenIds, maxInputAmount);

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
        pair.nftBuy(tokenIds, maxInputAmount);

        // assert
        assertEq(
            usd.balanceOf(address(pair)) - balanceBefore,
            maxInputAmount,
            "Should have transferred base tokens to pair"
        );
        assertEq(
            thisBalanceBefore - usd.balanceOf(address(this)),
            maxInputAmount,
            "Should have transferred base tokens from sender"
        );
    }

    function testItTransfersNfts() public {
        // act
        pair.nftBuy(tokenIds, maxInputAmount);

        // assert
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(
                bayc.ownerOf(i),
                address(this),
                "Should have sent bayc to sender"
            );
        }
    }

    function testItRevertsSlippageOnBuy() public {
        // arrange
        maxInputAmount -= 1; // subtract 1 to cause revert

        // act
        vm.expectRevert("Slippage: amount in");
        pair.nftBuy(tokenIds, maxInputAmount);
    }

    function testItBurnsFractionalTokens() public {
        // arrange
        uint256 totalSupplyBefore = pair.totalSupply();

        // act
        pair.nftBuy(tokenIds, maxInputAmount);

        // assert
        assertEq(
            totalSupplyBefore - pair.totalSupply(),
            tokenIds.length * 1e18,
            "Should have burned fractional tokens"
        );
    }
}
