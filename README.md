# Penguin Finance

Penguin finance is a fully on-chain NFT AMM that allows you to trade every NFT in a collection (from floors to superrares). You can also trade fractional amounts of each NFT too.
It's designed with a heavy emphasis on composability, flexibility and usability.

## Getting started
```
yarn
forge install
forge test --gas-report
```

## Coverage

```
| File                             | % Lines          | % Statements     | % Branches     | % Funcs        |
|----------------------------------|------------------|------------------|----------------|----------------|
| script/CreateFakePunks.s.sol     | 0.00% (0/11)     | 0.00% (0/12)     | 100.00% (0/0)  | 0.00% (0/4)    |
| script/CreatePair.s.sol          | 84.00% (21/25)   | 84.21% (32/38)   | 100.00% (0/0)  | 50.00% (2/4)   |
| script/Deploy.s.sol              | 0.00% (0/3)      | 0.00% (0/4)      | 100.00% (0/0)  | 0.00% (0/2)    |
| src/LpToken.sol                  | 100.00% (2/2)    | 100.00% (2/2)    | 100.00% (0/0)  | 100.00% (2/2)  |
| src/Pair.sol                     | 97.89% (93/95)   | 98.32% (117/119) | 95.24% (40/42) | 81.82% (18/22) |
| src/Penguin.sol                  | 100.00% (13/13)  | 100.00% (17/17)  | 100.00% (8/8)  | 100.00% (2/2)  |
| test/Shared/Mocks/MockERC721.sol | 50.00% (1/2)     | 50.00% (1/2)     | 100.00% (0/0)  | 50.00% (1/2)   |
| Total                            | 86.09% (130/151) | 87.11% (169/194) | 96.00% (48/50) | 65.79% (25/38) |
```