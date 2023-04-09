// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/auth/Owned.sol";

import "./Pair.sol";
import "./SafeERC20Namer.sol";

contract Penguin is Owned {
    using SafeERC20Namer for address;

    constructor() Owned(msg.sender) {}

    /**
     * @dev Creates a new Pair contract instance.
     * @param nft The address of the NFT contract.
     * @param baseToken The address of the base token contract.
     * @return The newly created Pair contract instance.
     */
    function create(address nft, address baseToken) public returns (Pair) {
        string memory baseTokenSymbol = baseToken == address(0)
            ? "ETH"
            : baseToken.tokenSymbol();
        string memory nftSymbol = nft.tokenSymbol();
        string memory nftName = nft.tokenName();
        string memory pairSymbol = string.concat(
            nftSymbol,
            ":",
            baseTokenSymbol
        );

        return new Pair(nft, baseToken, pairSymbol, nftName, nftSymbol);
    }
}
