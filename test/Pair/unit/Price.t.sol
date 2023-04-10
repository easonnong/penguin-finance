// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../Shared/Fixture.t.sol";

contract PriceTest is Fixture {
    using stdStorage for StdStorage;

    function testItReturnsCorrectPrice() public {
        // arrange
        uint256 baseTokenReserves = 500;
        uint256 fractionalTokenReserves = 1000;
        uint256 expectedPrice = (baseTokenReserves * 1e18) /
            fractionalTokenReserves;

        // forgefmt: disable-next-item
        stdstore
            .target(address(usd))
            .sig("balanceOf(address)")
            .with_key(address(pair))
            .checked_write(baseTokenReserves);

        // forgefmt: disable-next-item
        stdstore
            .target(address(pair))
            .sig("balanceOf(address)")
            .with_key(address(pair))
            .checked_write(fractionalTokenReserves);

        // act
        uint256 price = pair.price();

        // assert
        assertEq(price, expectedPrice, "Price does not match");
    }
}
