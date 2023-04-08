// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../src/Pair.sol";
import "../Shared/Fixture.t.sol";

contract BuyTest is Fixture {
    uint256 baseTokenAmount = 100;
    uint256 fractionalTokenAmount = 30;

    function setUp() public {
        deal(address(usd), address(this), baseTokenAmount, true);
        deal(address(pair), address(this), fractionalTokenAmount, true);

        usd.approve(address(pair), type(uint256).max);
    }
}
