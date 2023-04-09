// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../shared/Fixture.t.sol";

contract CreateTest is Fixture {
    function testItReturnsPair() public {
        // arrange
        address nft = address(0xbeef);
        address baseToken = address(0xcafe);

        // act
        address pair = address(penguin.create(nft, baseToken));

        // assert
        assertTrue(pair != address(0), "Should have deployed pair");
    }

    function testItSetsSymbols() public {
        // arrange
        address nft = 0xbEEFB00b00000000000000000000000000000000;
        address baseToken = 0xCAFE000000000000000000000000000000000000;

        // act
        Pair pair = penguin.create(nft, baseToken);
        LpToken lpToken = LpToken(pair.lpToken());

        // assert
        assertEq(
            pair.symbol(),
            "f0xbeef",
            "Should have set fractional token symbol"
        );
        assertEq(
            pair.name(),
            "0xbeefb00b00000000000000000000000000000000 fractional token",
            "Should have set fractional token name"
        );
        assertEq(
            lpToken.symbol(),
            "LP-0xbeef:0xcafe",
            "Should have set lp symbol"
        );
        assertEq(
            lpToken.name(),
            "0xbeef:0xcafe LP token",
            "Should have set lp name"
        );
    }
}
