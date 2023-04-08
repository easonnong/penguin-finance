// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../shared/Fixture.t.sol";
import "../../src/Penguin.sol";

contract AddTest is Fixture {
    uint256[] public tokenIds;

    function setUp() public {
        bayc.setApprovalForAll(address(pair), true);

        for (uint256 i = 0; i < 5; i++) {
            bayc.mint(address(this), i);
            tokenIds.push(i);
        }
    }

    function testItTransfersTokens() public {
        // act
        pair.wrap(tokenIds);

        // assert
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(
                bayc.ownerOf(i),
                address(pair),
                "Should have sent bayc to pair"
            );
        }
    }

    function testItMintsFractionalTokens() public {
        // arrange
        uint256 expectedFractionalTokens = tokenIds.length * 1e18;

        // act
        pair.wrap(tokenIds);

        // assert
        assertEq(
            pair.balanceOf(address(this)),
            expectedFractionalTokens,
            "Should have minted fractional tokens to sender"
        );
        assertEq(
            pair.totalSupply(),
            expectedFractionalTokens,
            "Should have minted fractional tokens"
        );
    }
}