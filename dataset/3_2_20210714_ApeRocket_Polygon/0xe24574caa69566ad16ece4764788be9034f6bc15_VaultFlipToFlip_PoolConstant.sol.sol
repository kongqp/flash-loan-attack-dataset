// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

library PoolConstant {
    enum PoolTypes {
        SpaceStake, // no perf fee
        BananaStake,
        FlipToFlip,
        FlipToBanana,
        Space, // no perf fee
        SpaceETH,
        SpaceToSpace
    }

    struct PoolInfoBSC {
        address pool;
        uint256 balance;
        uint256 principal;
        uint256 available;
        uint256 tvl;
        uint256 utilized;
        uint256 liquidity;
        uint256 pBASE;
        uint256 pSPACE;
        uint256 depositedAt;
        uint256 feeDuration;
        uint256 feePercentage;
    }
}
