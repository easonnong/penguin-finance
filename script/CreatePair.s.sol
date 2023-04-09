// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "solmate/utils/LibString.sol";

import "../src/Penguin.sol";
import "../src/Pair.sol";

contract CreatePairScript is Script {
    using stdJson for string;

    function run() public {
        vm.broadcast();
    }

    function create(
        address nft,
        address baseToken,
        string memory rankingFile,
        address penguin
    ) public returns (Pair) {
        // generate the merkle root
        bytes32 merkleRoot = generateMerkleRoot(rankingFile);

        // create the pair
        Pair pair = Penguin(penguin).create(nft, baseToken, merkleRoot);

        return pair;
    }

    function generateMerkleRoot(
        string memory rankingFile
    ) public returns (bytes32) {
        string[] memory inputs = new string[](3);

        inputs[0] = "node";
        inputs[1] = "./script/helpers/generate-merkle-root.js";
        inputs[2] = rankingFile;

        bytes memory res = vm.ffi(inputs);
        bytes32 output = abi.decode(res, (bytes32));

        return output;
    }

    function generateMerkleProofs(
        string memory rankingFile,
        uint256[] memory tokenIds
    ) public returns (bytes32[][] memory) {
        bytes32[][] memory proofs = new bytes32[][](tokenIds.length);

        string[] memory inputs = new string[](4);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            inputs[0] = "node";
            inputs[1] = "./script/helpers/generate-merkle-proof.js";
            inputs[2] = rankingFile;
            inputs[3] = LibString.toString(tokenIds[i]);

            bytes memory res = vm.ffi(inputs);
            bytes32[] memory output = abi.decode(res, (bytes32[]));
            proofs[i] = output;
        }

        return proofs;
    }
}
