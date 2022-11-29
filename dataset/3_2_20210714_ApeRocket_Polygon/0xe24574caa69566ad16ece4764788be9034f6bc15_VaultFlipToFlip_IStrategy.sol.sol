// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "../libraries/PoolConstant.sol";
import "./IVaultController.sol";

interface IStrategy is IVaultController {
    function deposit(uint256 _amount) external;

    function depositAll() external;

    function withdraw(uint256 _amount) external; /// SPACE STAKING POOL ONLY

    function withdrawAll() external;

    function getReward() external; // SPACE STAKING POOL ONLY

    function harvest() external;

    function stakeTo(uint256 amount, address account) external;

    function totalSupply() external view returns (uint256);

    function balance() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function sharesOf(address account) external view returns (uint256);

    function principalOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function withdrawableBalanceOf(address account)
        external
        view
        returns (uint256); /// SPACE STAKING POOL ONLY

    function priceShare() external view returns (uint256);

    /** ========== Strategy Information ========== */

    function pid() external view returns (uint256);

    function poolType() external view returns (PoolConstant.PoolTypes);

    function depositedAt(address account) external view returns (uint256);

    function rewardsToken() external view returns (address);

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(
        address indexed user,
        uint256 amount,
        uint256 withdrawalFee
    );
    event ProfitPaid(
        address indexed user,
        uint256 profit,
        uint256 performanceFee
    );
    event SpacePaid(
        address indexed user,
        uint256 profit,
        uint256 performanceFee
    );
    event Harvested(uint256 profit);
}
