// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Shared/Fixture.t.sol";
import "../../src/Penguin.sol";

contract NftSellTest is Fixture {
    uint256 public minOutputAmount;
    uint256[] public tokenIds;

    function setUp() public {
        uint256 baseTokenAmount = 100;
        uint256 fractionalTokenAmount = 30;

        deal(address(usd), address(this), baseTokenAmount, true);
        deal(address(pair), address(this), fractionalTokenAmount, true);
        usd.approve(address(pair), type(uint256).max);

        uint256 minLpTokenAmount = baseTokenAmount * fractionalTokenAmount;
        pair.add(baseTokenAmount, fractionalTokenAmount, minLpTokenAmount);

        for (uint256 i = 0; i < 5; i++) {
            bayc.mint(address(this), i);
            tokenIds.push(i);
        }

        bayc.setApprovalForAll(address(pair), true);

        minOutputAmount =
            (tokenIds.length * 1e18 * pair.baseTokenReserves()) /
            (pair.fractionalTokenReserves() + tokenIds.length * 1e18);
    }

    function testItReturnsOutputAmount() public {
        // arrange
        uint256 expectedOutputAmount = minOutputAmount;

        // act
        uint256 outputAmount = pair.nftSell(tokenIds, expectedOutputAmount);

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
        pair.nftSell(tokenIds, minOutputAmount);

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

    function testItTransfersNfts() public {
        // act
        pair.nftSell(tokenIds, minOutputAmount);

        // assert
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(
                bayc.ownerOf(i),
                address(pair),
                "Should have sent bayc to pair"
            );
        }
    }

    function testItRevertsSlippageOnSell() public {
        // arrange
        minOutputAmount += 1; // add 1 to cause revert

        // act
        vm.expectRevert("Slippage: amount out");
        pair.nftSell(tokenIds, minOutputAmount);
    }

    function testItMintsFractionalTokens() public {
        // arrange
        uint256 totalSupplyBefore = pair.totalSupply();
        uint256 balanceBefore = pair.balanceOf(address(pair));

        // act
        pair.nftSell(tokenIds, minOutputAmount);

        // assert
        assertEq(
            pair.totalSupply() - totalSupplyBefore,
            tokenIds.length * 1e18,
            "Should have minted fractional tokens"
        );
        assertEq(
            pair.balanceOf(address(pair)) - balanceBefore,
            tokenIds.length * 1e18,
            "Should have minted fractional tokens to pair"
        );
    }
}
