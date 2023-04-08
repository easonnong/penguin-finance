// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import "../../src/Penguin.sol";
import "../../src/Pair.sol";
import "./Mocks/MockERC721.sol";
import "./Mocks/MockERC20.sol";

contract Fixture is Test {
    MockERC721 public bayc;
    MockERC20 public usd;
    LpToken public lpToken;

    Penguin public penguin;
    Pair public pair;

    address public hacker = address(0x123);

    constructor() {
        penguin = new Penguin();

        bayc = new MockERC721("Bored Ape", "BAYC");
        usd = new MockERC20("Us Dollar", "USD");

        pair = penguin.create(address(bayc), address(usd));
        lpToken = LpToken(pair.lpToken());

        vm.label(hacker, "hacker");
        vm.label(address(penguin), "penguin");
        vm.label(address(bayc), "bayc");
        vm.label(address(usd), "usd");
        vm.label(address(pair), "pair");
        vm.label(address(lpToken), "LP-token");
    }
}
