// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IZap {
    function zapOut(address _from, uint256 amount) external;

    function zapIn(address _to) external payable;

    function zapInToken(
        address _from,
        uint256 amount,
        address _to
    ) external;
}
