// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../src/Penguin.sol";

contract PenguinTest is Test {
    Penguin public penguin;

    function setUp() public {
        penguin = new Penguin();
    }
}
