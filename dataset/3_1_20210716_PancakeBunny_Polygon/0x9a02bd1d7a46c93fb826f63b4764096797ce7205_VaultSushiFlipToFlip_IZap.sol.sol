// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IZap {
    function covers(address _token) external view returns (bool);

    function zapOut(address _from, uint amount) external;
    function zapIn(address _to) external payable;
    function zapInToken(address _from, uint amount, address _to) external;
}