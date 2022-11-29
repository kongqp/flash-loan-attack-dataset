//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IFlurryUpkeep {
    /**
     * @dev checkUpkeep compatible.
     * Return upkeepNeeded (in bool) and performData (in bytes) and untilKeepNeeded (in uint).
     */
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @dev performUpkeep compatible.
     */
    function performUpkeep(bytes calldata performData) external;
}
