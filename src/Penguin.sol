// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Pair.sol";
import "lib/SafeERC20Namer.sol";

contract Penguin {
    using SafeERC20Namer for address;

    function create(
        address nft,
        address baseToken,
        bytes32 merkleRoot
    ) public returns (Pair) {
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

        return
            new Pair(
                nft,
                baseToken,
                merkleRoot,
                pairSymbol,
                nftName,
                nftSymbol
            );
    }
}
