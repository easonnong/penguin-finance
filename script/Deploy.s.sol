// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/Penguin.sol";

contract DeployScript is Script {
    using stdJson for string;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        Penguin penguin = new Penguin();

        console.log("caviar:", address(penguin));
    }
}
