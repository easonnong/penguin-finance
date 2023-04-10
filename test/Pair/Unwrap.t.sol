// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Shared/Fixture.t.sol";
import "../../src/Penguin.sol";
import "solmate/tokens/ERC721.sol";

contract UnwrapTest is Fixture, ERC721TokenReceiver {
    event Unwrap(uint256[] tokenIds);

    uint256[] public tokenIds;
    bytes32[][] public proofs;

    function setUp() public {
        bayc.setApprovalForAll(address(pair), true);

        for (uint256 i = 0; i < 5; i++) {
            bayc.mint(address(this), i);
            tokenIds.push(i);
        }

        pair.wrap(tokenIds, proofs);
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

    function testItEmitsUnwrapEvent() public {
        // act
        vm.expectEmit(true, true, true, true);
        emit Unwrap(tokenIds);
        pair.unwrap(tokenIds);
    }
}
