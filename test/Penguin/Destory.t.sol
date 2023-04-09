// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Shared/Fixture.t.sol";

contract DestroyTest is Fixture {
    using stdStorage for StdStorage;

    event Destroy(
        address indexed nft,
        address indexed baseToken,
        bytes32 indexed merkleRoot
    );

    address public prankedAddress;

    function setUp() public {
        prankedAddress = address(0xbabe);

        stdstore
            .target(address(penguin))
            .sig("pairs(address,address,bytes32)")
            .with_key(address(this))
            .with_key(address(this))
            .with_key(bytes32(0))
            .depth(0)
            .checked_write(prankedAddress);
    }

    function testItRemovesPairFromMapping() public {
        // act
        vm.prank(prankedAddress);
        penguin.destroy(address(this), address(this), bytes32(0));

        // assert
        assertEq(
            penguin.pairs(address(this), address(this), bytes32(0)),
            address(0),
            "Should have removed pair"
        );
    }

    function testOnlyPairCanRemoveItself() public {
        // act
        vm.expectRevert("Only pair can destroy itself");
        penguin.destroy(address(this), address(this), bytes32(0));
    }

    function testItEmitsDestroyEvent() public {
        // arrange
        vm.expectEmit(true, true, true, true);
        emit Destroy(address(this), address(this), bytes32(0));

        // act
        vm.prank(prankedAddress);
        penguin.destroy(address(this), address(this), bytes32(0));
    }

    function testItRemovesPairFromMapping(
        address nft,
        address baseToken,
        bytes32 merkleRoot,
        address _prankedAddress
    ) public {
        // arrange
        stdstore
            .target(address(penguin))
            .sig("pairs(address,address,bytes32)")
            .with_key(nft)
            .with_key(baseToken)
            .with_key(merkleRoot)
            .depth(0)
            .checked_write(_prankedAddress);

        // act
        vm.prank(_prankedAddress);
        penguin.destroy(nft, baseToken, merkleRoot);

        // assert
        assertEq(
            penguin.pairs(nft, baseToken, merkleRoot),
            address(0),
            "Should have removed pair"
        );
    }
}
