// SPDX-License-Identifier: MIT
// Version @2021-05
// Source: Pancake Bunny
/*
 █████╗ ██████╗ ███████╗██████╗  ██████╗  ██████╗██╗  ██╗███████╗████████╗
██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔════╝██║ ██╔╝██╔════╝╚══██╔══╝
███████║██████╔╝█████╗  ██████╔╝██║   ██║██║     █████╔╝ █████╗     ██║   
██╔══██║██╔═══╝ ██╔══╝  ██╔══██╗██║   ██║██║     ██╔═██╗ ██╔══╝     ██║   
██║  ██║██║     ███████╗██║  ██║╚██████╔╝╚██████╗██║  ██╗███████╗   ██║   
╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝  
 */
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface ISpaceChef {
    struct UserInfo {
        uint256 balance;
        uint256 pending;
        uint256 rewardPaid;
    }

    struct VaultInfo {
        address token;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accSpacePerShare;
    }

    function spacePerBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function vaultInfoOf(address vault) external view returns (VaultInfo memory);

    function vaultUserInfoOf(address vault, address user) external view returns (UserInfo memory);

    function pendingSpace(address vault, address user) external view returns (uint256);

    function notifyDeposited(address user, uint256 amount) external;

    function notifyWithdrawn(address user, uint256 amount) external;

    function safeSpaceTransfer(address user) external returns (uint256);
}
