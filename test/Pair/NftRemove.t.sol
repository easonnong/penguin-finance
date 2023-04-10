// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Shared/Fixture.t.sol";
import "../../src/Penguin.sol";
import "solmate/tokens/ERC721.sol";

contract NftRemoveTest is Fixture, ERC721TokenReceiver {
    uint256 public totalBaseTokenAmount = 3.15e18;
    uint256 public totalLpTokenAmount;
    uint256[] public tokenIds;
    bytes32[][] public proofs;

    function setUp() public {
        deal(address(usd), address(this), totalBaseTokenAmount, true);
        for (uint256 i = 0; i < 6; i++) {
            bayc.mint(address(this), i);
            tokenIds.push(i);
        }

        bayc.setApprovalForAll(address(pair), true);
        usd.approve(address(pair), type(uint256).max);

        uint256 minLpTokenAmount = Math.sqrt(
            totalBaseTokenAmount * tokenIds.length * 1e18
        );
        totalLpTokenAmount = pair.nftAdd(
            totalBaseTokenAmount,
            tokenIds,
            minLpTokenAmount,
            proofs
        );

        tokenIds.pop();
        tokenIds.pop();
        tokenIds.pop();
    }

    function testItReturnsBaseTokenAmountAndFractionalTokenAmount() public {
        // arrange
        uint256 lpTokenAmount = (totalLpTokenAmount * tokenIds.length * 1e18) /
            pair.fractionalTokenReserves();
        uint256 expectedBaseTokenAmount = (totalBaseTokenAmount *
            tokenIds.length *
            1e18) / pair.fractionalTokenReserves();
        uint256 expectedFractionalTokenAmount = tokenIds.length * 1e18;

        // act
        (uint256 baseTokenAmount, uint256 fractionalTokenAmount) = pair
            .nftRemove(lpTokenAmount, expectedBaseTokenAmount, tokenIds);

        // assert
        assertEq(
            baseTokenAmount,
            expectedBaseTokenAmount,
            "Should have returned correct base token amount"
        );
        assertEq(
            fractionalTokenAmount,
            expectedFractionalTokenAmount,
            "Should have returned correct fractional token amount"
        );
    }

    function testItBurnsLpTokens() public {
        // arrange
        uint256 lpTokenAmount = (totalLpTokenAmount * tokenIds.length * 1e18) /
            pair.fractionalTokenReserves();
        uint256 minBaseTokenOutputAmount = (totalBaseTokenAmount *
            tokenIds.length *
            1e18) / pair.fractionalTokenReserves();
        uint256 balanceBefore = lpToken.balanceOf(address(this));
        uint256 totalSupplyBefore = lpToken.totalSupply();

        // act
        pair.nftRemove(lpTokenAmount, minBaseTokenOutputAmount, tokenIds);

        // assert
        assertEq(
            balanceBefore - lpToken.balanceOf(address(this)),
            lpTokenAmount,
            "Should have burned lp tokens from sender"
        );
        assertEq(
            totalSupplyBefore - lpToken.totalSupply(),
            lpTokenAmount,
            "Should have burned lp tokens"
        );
    }

    function testItTransfersBaseTokens() public {
        // arrange
        uint256 lpTokenAmount = (totalLpTokenAmount * tokenIds.length * 1e18) /
            pair.fractionalTokenReserves();
        uint256 minBaseTokenOutputAmount = (totalBaseTokenAmount *
            tokenIds.length *
            1e18) / pair.fractionalTokenReserves();
        uint256 thisBalanceBefore = usd.balanceOf(address(this));
        uint256 balanceBefore = usd.balanceOf(address(pair));

        // act
        pair.nftRemove(lpTokenAmount, minBaseTokenOutputAmount, tokenIds);

        // assert
        assertEq(
            usd.balanceOf(address(this)) - thisBalanceBefore,
            minBaseTokenOutputAmount,
            "Should have transferred base tokens to sender"
        );

        assertEq(
            balanceBefore - usd.balanceOf(address(pair)),
            minBaseTokenOutputAmount,
            "Should have transferred base tokens from pair"
        );
    }

    function testItTransfersNfts() public {
        // arrange
        uint256 lpTokenAmount = (totalLpTokenAmount * tokenIds.length * 1e18) /
            pair.fractionalTokenReserves();
        uint256 minBaseTokenOutputAmount = (totalBaseTokenAmount *
            tokenIds.length *
            1e18) / pair.fractionalTokenReserves();

        // act
        pair.nftRemove(lpTokenAmount, minBaseTokenOutputAmount, tokenIds);

        // assert
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(
                bayc.ownerOf(i),
                address(this),
                "Should have sent bayc to sender"
            );
        }
    }

    function testItRevertsNftSlippage() public {
        // arrange
        uint256 lpTokenAmount = (totalLpTokenAmount * tokenIds.length * 1e18) /
            pair.fractionalTokenReserves();
        uint256 minBaseTokenOutputAmount = (totalBaseTokenAmount *
            tokenIds.length *
            1e18) / pair.fractionalTokenReserves();
        tokenIds.push(100); // add a token to cause revert

        // act
        vm.expectRevert("Slippage: fractional token amount out");
        pair.nftRemove(lpTokenAmount, minBaseTokenOutputAmount, tokenIds);
    }

    function testItRevertsBaseTokenSlippage() public {
        // arrange
        uint256 lpTokenAmount = (totalLpTokenAmount * tokenIds.length * 1e18) /
            pair.fractionalTokenReserves();
        uint256 minBaseTokenOutputAmount = (totalBaseTokenAmount *
            tokenIds.length *
            1e18) /
            pair.fractionalTokenReserves() +
            1; // add 1 to cause revert

        // act
        vm.expectRevert("Slippage: base token amount out");
        pair.nftRemove(lpTokenAmount, minBaseTokenOutputAmount, tokenIds);
    }

    function testItRemovesWithMerkleProof() public {
        // arrange
        deal(address(usd), address(this), totalBaseTokenAmount, true);
        delete tokenIds;
        for (uint256 i = 0; i < 6; i++) {
            bayc.mint(address(this), i + 6);
            tokenIds.push(i + 6);
        }

        Pair pair = createPairScript.create(
            address(bayc),
            address(usd),
            "YEET-mids.json",
            address(penguin)
        );
        proofs = createPairScript.generateMerkleProofs(
            "YEET-mids.json",
            tokenIds
        );

        bayc.setApprovalForAll(address(pair), true);
        usd.approve(address(pair), type(uint256).max);

        uint256 minLpTokenAmount = Math.sqrt(
            totalBaseTokenAmount * tokenIds.length * 1e18
        );
        totalLpTokenAmount = pair.nftAdd(
            totalBaseTokenAmount,
            tokenIds,
            minLpTokenAmount,
            proofs
        );

        tokenIds.pop();
        tokenIds.pop();
        tokenIds.pop();

        uint256 lpTokenAmount = (totalLpTokenAmount * tokenIds.length * 1e18) /
            pair.fractionalTokenReserves();
        uint256 minBaseTokenOutputAmount = (totalBaseTokenAmount *
            tokenIds.length *
            1e18) / pair.fractionalTokenReserves();
        proofs = createPairScript.generateMerkleProofs(
            "YEET-mids.json",
            tokenIds
        );

        // act
        pair.nftRemove(lpTokenAmount, minBaseTokenOutputAmount, tokenIds);

        // assert
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(
                bayc.ownerOf(tokenIds[i]),
                address(this),
                "Should have sent bayc to sender"
            );
        }
    }
}
