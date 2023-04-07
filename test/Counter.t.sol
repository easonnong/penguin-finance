// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../src/Exchange.sol";

contract ExchangeTest is Test {
    Exchange public exchange;

    function setUp() public {
        exchange = new Exchange();
    }
}
