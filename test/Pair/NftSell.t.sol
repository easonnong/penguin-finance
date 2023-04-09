// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Shared/Fixture.t.sol";
import "../../src/Penguin.sol";

contract NftSellTest is Fixture {
    uint256 public minOutputAmount;
    uint256[] public tokenIds;
    bytes32[][] public proofs;

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
            (tokenIds.length * 1e18 * 997 * pair.baseTokenReserves()) /
            (pair.fractionalTokenReserves() *
                1000 +
                tokenIds.length *
                1e18 *
                997);
    }

    function testItReturnsOutputAmount() public {
        // arrange
        uint256 expectedOutputAmount = minOutputAmount;

        // act
        uint256 outputAmount = pair.nftSell(
            tokenIds,
            expectedOutputAmount,
            proofs
        );

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
        pair.nftSell(tokenIds, minOutputAmount, proofs);

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
        pair.nftSell(tokenIds, minOutputAmount, proofs);

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
        pair.nftSell(tokenIds, minOutputAmount, proofs);
    }

    function testItMintsFractionalTokens() public {
        // arrange
        uint256 totalSupplyBefore = pair.totalSupply();
        uint256 balanceBefore = pair.balanceOf(address(pair));

        // act
        pair.nftSell(tokenIds, minOutputAmount, proofs);

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

    function testItSellsWithMerkleProof() public {
        Pair pair = createPairScript.create(
            address(bayc),
            address(usd),
            "YEET-mids.json",
            address(penguin)
        );

        uint256 baseTokenAmount = 69.69e18;
        uint256 fractionalTokenAmount = 420.42e18;

        deal(address(usd), address(this), baseTokenAmount, true);
        deal(address(pair), address(this), fractionalTokenAmount, true);
        usd.approve(address(pair), type(uint256).max);

        uint256 minLpTokenAmount = baseTokenAmount * fractionalTokenAmount;
        pair.add(baseTokenAmount, fractionalTokenAmount, minLpTokenAmount);

        proofs = createPairScript.generateMerkleProofs(
            "YEET-mids.json",
            tokenIds
        );
        bayc.setApprovalForAll(address(pair), true);

        // act
        pair.nftSell(tokenIds, minOutputAmount, proofs);

        // assert
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(
                bayc.ownerOf(tokenIds[i]),
                address(pair),
                "Should have sent bayc to pair"
            );
        }
    }
}
