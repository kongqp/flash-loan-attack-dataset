// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface ISpaceMinter {
    function isMinter(address) external view returns (bool);

    function amountSpaceToMint(uint256 bnbProfit)
        external
        view
        returns (uint256);

    function withdrawalFee(uint256 amount, uint256 depositedAt)
        external
        view
        returns (uint256);

    function performanceFee(uint256 profit) external view returns (uint256);

    function mintFor(
        address flip,
        uint256 withdrawalFeeAmount,
        uint256 performanceFeeAmount,
        address dest,
        uint256 depositedAt
    ) external payable;

    function amountToMintPerProfit() external view returns (uint256);

    function withdrawalFeeFreePeriod() external view returns (uint256);

    function withdrawalFeeRate() external view returns (uint256);

    function updateAccessToMint(address minter, bool canMint) external;

    function mint(address to, uint256 amount) external;

    function safeSpaceTransfer(address to, uint256 amount) external;

    function mintGov(uint256 amount) external;

    function mintForSpaceLauncher(uint256 amount, address launcher) external;
}
