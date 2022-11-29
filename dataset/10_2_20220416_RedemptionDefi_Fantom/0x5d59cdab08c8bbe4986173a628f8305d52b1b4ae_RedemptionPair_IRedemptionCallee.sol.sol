// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IRedemptionCallee {
    function RedemptionCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}