// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IApeChef {
    function poolInfo(uint256 _pid)
        external
        view
        returns (
            uint128,
            uint64,
            uint64
        );

    function lpToken(uint256 _pid) external view returns (address);

    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (uint256, uint256);

    function pendingBanana(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function bananaPerSecond() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function emergencyWithdraw(uint256 pid, address to) external;

    function harvest(uint256 pid, address to) external;

    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function withdrawAndHarvest(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external;
}
