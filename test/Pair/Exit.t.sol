// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/tokens/ERC721.sol";

import "../shared/Fixture.t.sol";
import "../../src/Penguin.sol";

contract WrapTest is Fixture, ERC721TokenReceiver {
    uint256[] public tokenIds;

    function setUp() public {
        bayc.setApprovalForAll(address(pair), true);

        for (uint256 i = 0; i < 5; i++) {
            bayc.mint(address(this), i);
            tokenIds.push(i);
        }
    }

    function testExitSetsCloseTimestamp() public {
        // arrange
        uint256 expectedCloseTimestamp = block.timestamp;

        // act
        pair.exit();

        // assert
        assertEq(
            pair.closeTimestamp(),
            expectedCloseTimestamp,
            "Should have set close timestamp"
        );
    }

    function testCannotExitIfNotAdmin() public {
        // act
        vm.prank(address(0xabc));
        vm.expectRevert("Exit: not creator");
        pair.exit();

        // assert
        assertEq(
            pair.closeTimestamp(),
            0,
            "Should not have set close timestamp"
        );
    }

    function testCannotWithdrawIfNotAdmin() public {
        // arrange
        pair.exit();

        // act
        vm.prank(address(0xabc));
        vm.expectRevert("Withdraw: not creator");
        pair.withdraw(1);
    }

    function testCannotWithdrawIfNotClosed() public {
        // act
        vm.expectRevert("Withdraw not initiated");
        pair.withdraw(1);
    }

    function testCannotWithdrawIfNotEnoughTimeElapsed() public {
        // arrange
        pair.exit();

        // act
        vm.expectRevert("Not withdrawable yet");
        pair.withdraw(1);
    }

    function testItTransfersNftsAfterWithdraw() public {
        // arrange
        pair.exit();
        skip(1 days);
        uint256 tokenId = 1;
        bayc.transferFrom(address(this), address(pair), tokenId);

        // act
        pair.withdraw(tokenId);

        // assert
        assertEq(
            bayc.ownerOf(tokenId),
            address(this),
            "Should have sent bayc to sender"
        );
    }
}
