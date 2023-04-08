// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../shared/Fixture.t.sol";
import "../../src/Penguin.sol";

contract UnwrapTest is Fixture {
    uint256[] public tokenIds;

    function setUp() public {
        bayc.setApprovalForAll(address(pair), true);

        for (uint256 i = 0; i < 5; i++) {
            bayc.mint(address(this), i);
            tokenIds.push(i);
        }

        pair.wrap(tokenIds);
    }

    function testItTransfersTokens() public {
        // act
        pair.unwrap(tokenIds);

        // assert
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(
                bayc.ownerOf(i),
                address(this),
                "Should have sent bayc to sender"
            );
        }
    }

    function testItBurnsFractionalTokens() public {
        // arrange
        uint256 expectedFractionalTokensBurned = tokenIds.length * 1e18;
        uint256 balanceBefore = pair.balanceOf(address(this));
        uint256 totalSupplyBefore = pair.totalSupply();

        // act
        pair.unwrap(tokenIds);

        // assert
        assertEq(
            balanceBefore - pair.balanceOf(address(this)),
            expectedFractionalTokensBurned,
            "Should have burned fractional tokens from sender"
        );

        assertEq(
            totalSupplyBefore - pair.totalSupply(),
            expectedFractionalTokensBurned,
            "Should have burned fractional tokens"
        );
    }
}
