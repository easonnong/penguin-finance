// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/auth/Owned.sol";

import "./Pair.sol";

contract Penguin is Owned {
    constructor() Owned(msg.sender) {}

    /**
     * @dev Creates a new Pair contract instance.
     * @param nft The address of the NFT contract.
     * @param baseToken The address of the base token contract.
     * @return The newly created Pair contract instance.
     */
    function create(address nft, address baseToken) public returns (Pair) {
        return new Pair(nft, baseToken);
    }
}
