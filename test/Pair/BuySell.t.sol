// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../Shared/Fixture.t.sol";
import "../../src/Penguin.sol";

contract BuyTest is Fixture {
    uint256 public outputAmount = 1e18;

    function setUp() public {
        uint256 baseTokenAmount = 100e18;
        uint256 fractionalTokenAmount = 100e18;

        deal(address(usd), address(this), baseTokenAmount, true);
        deal(address(pair), address(this), fractionalTokenAmount, true);

        usd.approve(address(pair), type(uint256).max);

        uint256 minLpTokenAmount = baseTokenAmount * fractionalTokenAmount;
        pair.add(baseTokenAmount, fractionalTokenAmount, minLpTokenAmount);

        deal(address(ethPair), address(this), fractionalTokenAmount, true);
        ethPair.add{value: baseTokenAmount}(
            baseTokenAmount,
            fractionalTokenAmount,
            minLpTokenAmount
        );
    }

    function testBuySellInvariant() public {
        // buy the amount
        // uint256 maxInputAmount = pair.buyQuote(outputAmount);
        // deal(address(usd), address(this), maxInputAmount, true);
        // pair.buy(outputAmount, maxInputAmount);
        // // sell the same amount
        // console.log("f bal:", pair.balanceOf(address(this)));
        // uint256 minOutputAmount = pair.sellQuote(outputAmount);
        // uint256 ethOutputAmount = pair.sell(outputAmount, minOutputAmount);
        // // assert
        // assertEq(
        //     usd.balanceOf(address(this)), ((maxInputAmount * 994009) / 1000000), "Should have returned input amount"
        // );
    }
}
