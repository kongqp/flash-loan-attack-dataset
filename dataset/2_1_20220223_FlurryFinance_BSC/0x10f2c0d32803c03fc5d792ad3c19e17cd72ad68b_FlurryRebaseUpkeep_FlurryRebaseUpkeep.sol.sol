//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IFlurryUpkeep.sol";
import "../interfaces/IVault.sol";

/**
 * @notice Rebase Upkeep
 * This follows the keeper interface specified by ChainLink
 * checkUpKeep returns true if performUpkeep needs to be called
 * performUpkeep calls rebase on the registered Vaults
 *
 * This keeper is used to periodically rebase on Vault contracts to rebase RhoTokens
 * Effectively increases the totalSupply of RhoTokens
 */
contract FlurryRebaseUpkeep is OwnableUpgradeable, IFlurryUpkeep {
    uint256 public rebaseInterval; // Daily rebasing interval with 1 = 1 second
    uint256 public lastTimeStamp;

    IVault[] public vaults;
    mapping(address => bool) public vaultRegistered;

    function initialize(uint256 interval) external initializer {
        OwnableUpgradeable.__Ownable_init();
        rebaseInterval = interval;
        lastTimeStamp = block.timestamp;
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp >= lastTimeStamp + rebaseInterval);
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        lastTimeStamp = block.timestamp;
        for (uint256 i = 0; i < vaults.length; i++) {
            vaults[i].rebase();
        }
        performData;
    }

    function setLastTimeStamp(uint256 _lastTimeStamp) external onlyOwner {
        lastTimeStamp = _lastTimeStamp;
    }

    function setRebaseInterval(uint256 interval) external onlyOwner {
        rebaseInterval = interval;
    }

    function registerVault(address vaultAddr) external onlyOwner {
        require(vaultAddr != address(0), "Vault address is 0");
        require(!vaultRegistered[vaultAddr], "This vault is already registered.");
        vaults.push(IVault(vaultAddr));
        vaultRegistered[vaultAddr] = true;
    }
}
