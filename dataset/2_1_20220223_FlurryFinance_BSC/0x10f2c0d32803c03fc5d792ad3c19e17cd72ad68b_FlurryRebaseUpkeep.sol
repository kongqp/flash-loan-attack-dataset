{{
  "language": "Solidity",
  "sources": {
    "contracts/keeper/FlurryRebaseUpkeep.sol": {
      "content": "//SPDX-License-Identifier: MIT\r\npragma solidity 0.8.4;\r\n\r\nimport \"@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol\";\r\nimport \"../interfaces/IFlurryUpkeep.sol\";\r\nimport \"../interfaces/IVault.sol\";\r\n\r\n/**\r\n * @notice Rebase Upkeep\r\n * This follows the keeper interface specified by ChainLink\r\n * checkUpKeep returns true if performUpkeep needs to be called\r\n * performUpkeep calls rebase on the registered Vaults\r\n *\r\n * This keeper is used to periodically rebase on Vault contracts to rebase RhoTokens\r\n * Effectively increases the totalSupply of RhoTokens\r\n */\r\ncontract FlurryRebaseUpkeep is OwnableUpgradeable, IFlurryUpkeep {\r\n    uint256 public rebaseInterval; // Daily rebasing interval with 1 = 1 second\r\n    uint256 public lastTimeStamp;\r\n\r\n    IVault[] public vaults;\r\n    mapping(address => bool) public vaultRegistered;\r\n\r\n    function initialize(uint256 interval) external initializer {\r\n        OwnableUpgradeable.__Ownable_init();\r\n        rebaseInterval = interval;\r\n        lastTimeStamp = block.timestamp;\r\n    }\r\n\r\n    function checkUpkeep(bytes calldata checkData)\r\n        external\r\n        view\r\n        override\r\n        returns (bool upkeepNeeded, bytes memory performData)\r\n    {\r\n        upkeepNeeded = (block.timestamp >= lastTimeStamp + rebaseInterval);\r\n        performData = checkData;\r\n    }\r\n\r\n    function performUpkeep(bytes calldata performData) external override {\r\n        lastTimeStamp = block.timestamp;\r\n        for (uint256 i = 0; i < vaults.length; i++) {\r\n            vaults[i].rebase();\r\n        }\r\n        performData;\r\n    }\r\n\r\n    function setLastTimeStamp(uint256 _lastTimeStamp) external onlyOwner {\r\n        lastTimeStamp = _lastTimeStamp;\r\n    }\r\n\r\n    function setRebaseInterval(uint256 interval) external onlyOwner {\r\n        rebaseInterval = interval;\r\n    }\r\n\r\n    function registerVault(address vaultAddr) external onlyOwner {\r\n        require(vaultAddr != address(0), \"Vault address is 0\");\r\n        require(!vaultRegistered[vaultAddr], \"This vault is already registered.\");\r\n        vaults.push(IVault(vaultAddr));\r\n        vaultRegistered[vaultAddr] = true;\r\n    }\r\n}\r\n"
    },
    "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\nimport \"../utils/ContextUpgradeable.sol\";\nimport \"../proxy/utils/Initializable.sol\";\n\n/**\n * @dev Contract module which provides a basic access control mechanism, where\n * there is an account (an owner) that can be granted exclusive access to\n * specific functions.\n *\n * By default, the owner account will be the one that deploys the contract. This\n * can later be changed with {transferOwnership}.\n *\n * This module is used through inheritance. It will make available the modifier\n * `onlyOwner`, which can be applied to your functions to restrict their use to\n * the owner.\n */\nabstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {\n    address private _owner;\n\n    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);\n\n    /**\n     * @dev Initializes the contract setting the deployer as the initial owner.\n     */\n    function __Ownable_init() internal initializer {\n        __Context_init_unchained();\n        __Ownable_init_unchained();\n    }\n\n    function __Ownable_init_unchained() internal initializer {\n        _setOwner(_msgSender());\n    }\n\n    /**\n     * @dev Returns the address of the current owner.\n     */\n    function owner() public view virtual returns (address) {\n        return _owner;\n    }\n\n    /**\n     * @dev Throws if called by any account other than the owner.\n     */\n    modifier onlyOwner() {\n        require(owner() == _msgSender(), \"Ownable: caller is not the owner\");\n        _;\n    }\n\n    /**\n     * @dev Leaves the contract without owner. It will not be possible to call\n     * `onlyOwner` functions anymore. Can only be called by the current owner.\n     *\n     * NOTE: Renouncing ownership will leave the contract without an owner,\n     * thereby removing any functionality that is only available to the owner.\n     */\n    function renounceOwnership() public virtual onlyOwner {\n        _setOwner(address(0));\n    }\n\n    /**\n     * @dev Transfers ownership of the contract to a new account (`newOwner`).\n     * Can only be called by the current owner.\n     */\n    function transferOwnership(address newOwner) public virtual onlyOwner {\n        require(newOwner != address(0), \"Ownable: new owner is the zero address\");\n        _setOwner(newOwner);\n    }\n\n    function _setOwner(address newOwner) private {\n        address oldOwner = _owner;\n        _owner = newOwner;\n        emit OwnershipTransferred(oldOwner, newOwner);\n    }\n    uint256[49] private __gap;\n}\n"
    },
    "contracts/interfaces/IFlurryUpkeep.sol": {
      "content": "//SPDX-License-Identifier: MIT\r\npragma solidity 0.8.4;\r\n\r\ninterface IFlurryUpkeep {\r\n    /**\r\n     * @dev checkUpkeep compatible.\r\n     * Return upkeepNeeded (in bool) and performData (in bytes) and untilKeepNeeded (in uint).\r\n     */\r\n    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);\r\n\r\n    /**\r\n     * @dev performUpkeep compatible.\r\n     */\r\n    function performUpkeep(bytes calldata performData) external;\r\n}\r\n"
    },
    "contracts/interfaces/IVault.sol": {
      "content": "//SPDX-License-Identifier: MIT\r\npragma solidity 0.8.4;\r\n\r\nimport \"./IVaultConfig.sol\";\r\n\r\ninterface IVault {\r\n    event ReserveChanged(uint256 reserveBalance);\r\n    event RepurchasedFlurry(uint256 rhoTokenIn, uint256 flurryOut);\r\n    event RepurchaseFlurryFailed(uint256 rhoTokenIn);\r\n    event CollectRewardError(address indexed _from, address indexed _strategy, string _reason);\r\n    event CollectRewardUnknownError(address indexed _from, address indexed _strategy);\r\n    event VaultRatesChanged(uint256 supplyRate, uint256 indicativeSupplyRate);\r\n    event Log(string message);\r\n\r\n    /**\r\n     * @return accumulated rhoToken management fee in vault\r\n     */\r\n    function feeInRho() external view returns (uint256);\r\n\r\n    /**\r\n     * @dev getter function for cash reserve\r\n     * @return return cash reserve balance (in underlying) for vault\r\n     */\r\n    function reserve() external view returns (uint256);\r\n\r\n    /**\r\n     * @return True if the asset is supported by this vault\r\n     */\r\n    function supportsAsset(address _asset) external view returns (bool);\r\n\r\n    /**\r\n     * @dev function that trigggers the distribution of interest earned to Rho token holders\r\n     */\r\n    function rebase() external;\r\n\r\n    /**\r\n     * @dev function that trigggers allocation and unallocation of funds based on reserve pool bounds\r\n     */\r\n    function rebalance() external;\r\n\r\n    /**\r\n     * @dev function to mint RhoToken\r\n     * @param amount amount in underlying stablecoin\r\n     */\r\n    function mint(uint256 amount) external;\r\n\r\n    /**\r\n     * @dev function to redeem RhoToken\r\n     * @param amount amount of rhoTokens to be redeemed\r\n     */\r\n    function redeem(uint256 amount) external;\r\n\r\n    /**\r\n     * admin functions to withdraw random token transfer to this contract\r\n     */\r\n    function sweepERC20Token(address token, address to) external;\r\n\r\n    function sweepRhoTokenContractERC20Token(address token, address to) external;\r\n\r\n    /**\r\n     * @dev function to check strategies shoud collect reward\r\n     * @return List of boolean\r\n     */\r\n    function checkStrategiesCollectReward() external view returns (bool[] memory);\r\n\r\n    /**\r\n     * @return supply rate (pa) for Vault\r\n     */\r\n    function supplyRate() external view returns (uint256);\r\n\r\n    /**\r\n     * @dev function to collect strategies reward token\r\n     * @param collectList strategies to be collect\r\n     */\r\n    function collectStrategiesRewardTokenByIndex(uint16[] memory collectList) external returns (bool[] memory);\r\n\r\n    /**\r\n     * admin functions to withdraw fees\r\n     */\r\n    function withdrawFees(uint256 amount, address to) external;\r\n\r\n    /**\r\n     * @return true if feeInRho >= repurchaseFlurryThreshold, false otherwise\r\n     */\r\n    function shouldRepurchaseFlurry() external view returns (bool);\r\n\r\n    /**\r\n     * @dev Calculates the amount of rhoToken used to repurchase FLURRY.\r\n     * The selling is delegated to Token Exchange. FLURRY obtained\r\n     * is directly sent to Flurry Staking Rewards.\r\n     */\r\n    function repurchaseFlurry() external;\r\n\r\n    /**\r\n     * @return reference to IVaultConfig contract\r\n     */\r\n    function config() external view returns (IVaultConfig);\r\n\r\n    /**\r\n     * @return list of strategy addresses\r\n     */\r\n    function getStrategiesList() external view returns (IVaultConfig.Strategy[] memory);\r\n\r\n    /**\r\n     * @return no. of strategies registered\r\n     */\r\n    function getStrategiesListLength() external view returns (uint256);\r\n\r\n    /**\r\n     * @dev retire rhoStrategy from the Vault\r\n     * @param strategy address of IRhoStrategy\r\n     */\r\n    function retireStrategy(address strategy) external;\r\n\r\n    /**\r\n     * @dev indicative supply rate\r\n     * signifies the supply rate after next rebase\r\n     */\r\n    function indicativeSupplyRate() external view returns (uint256);\r\n}\r\n"
    },
    "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\nimport \"../proxy/utils/Initializable.sol\";\n\n/**\n * @dev Provides information about the current execution context, including the\n * sender of the transaction and its data. While these are generally available\n * via msg.sender and msg.data, they should not be accessed in such a direct\n * manner, since when dealing with meta-transactions the account sending and\n * paying for execution may not be the actual sender (as far as an application\n * is concerned).\n *\n * This contract is only required for intermediate, library-like contracts.\n */\nabstract contract ContextUpgradeable is Initializable {\n    function __Context_init() internal initializer {\n        __Context_init_unchained();\n    }\n\n    function __Context_init_unchained() internal initializer {\n    }\n    function _msgSender() internal view virtual returns (address) {\n        return msg.sender;\n    }\n\n    function _msgData() internal view virtual returns (bytes calldata) {\n        return msg.data;\n    }\n    uint256[50] private __gap;\n}\n"
    },
    "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\n/**\n * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed\n * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an\n * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer\n * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.\n *\n * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as\n * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.\n *\n * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure\n * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.\n */\nabstract contract Initializable {\n    /**\n     * @dev Indicates that the contract has been initialized.\n     */\n    bool private _initialized;\n\n    /**\n     * @dev Indicates that the contract is in the process of being initialized.\n     */\n    bool private _initializing;\n\n    /**\n     * @dev Modifier to protect an initializer function from being invoked twice.\n     */\n    modifier initializer() {\n        require(_initializing || !_initialized, \"Initializable: contract is already initialized\");\n\n        bool isTopLevelCall = !_initializing;\n        if (isTopLevelCall) {\n            _initializing = true;\n            _initialized = true;\n        }\n\n        _;\n\n        if (isTopLevelCall) {\n            _initializing = false;\n        }\n    }\n}\n"
    },
    "contracts/interfaces/IVaultConfig.sol": {
      "content": "//SPDX-License-Identifier: MIT\r\npragma solidity 0.8.4;\r\n\r\nimport \"./IRhoStrategy.sol\";\r\n\r\ninterface IVaultConfig {\r\n    event Log(string message);\r\n    event StrategyAdded(string name, address addr);\r\n    event StrategyRemoved(string name, address addr);\r\n    event StrategyRatesChanged(address indexed strategy, uint256 effRate, uint256 supplyRate, uint256 bonusRate);\r\n\r\n    struct Strategy {\r\n        string name;\r\n        IRhoStrategy target;\r\n    }\r\n\r\n    /**\r\n     * @return FLURRY token address\r\n     */\r\n    function flurryToken() external view returns (address);\r\n\r\n    /**\r\n     * @return Returns the address of the Rho token contract\r\n     */\r\n    function rhoToken() external view returns (address);\r\n\r\n    function rhoOne() external view returns (uint256);\r\n\r\n    /**\r\n     * Each Vault currently only supports one underlying asset\r\n     * @return Returns the contract address of the underlying asset\r\n     */\r\n    function underlying() external view returns (address);\r\n\r\n    function underlyingOne() external view returns (uint256);\r\n\r\n    /**\r\n     * @dev Getter function for Rho token minting fee\r\n     * @return Return the minting fee (in bps)\r\n     */\r\n    function mintingFee() external view returns (uint256);\r\n\r\n    /**\r\n     * @dev Getter function for Rho token redemption fee\r\n     * @return Return the redeem fee (in bps)\r\n     */\r\n    function redeemFee() external view returns (uint256);\r\n\r\n    /**\r\n     * @dev Getter function for allocation lowerbound and upperbound\r\n     */\r\n    function reserveBoundary(uint256 index) external view returns (uint256);\r\n\r\n    function managementFee() external view returns (uint256);\r\n\r\n    /**\r\n     * @dev The threshold (denominated in underlying asset ) over which rewards tokens will automatically\r\n     * be converted into the underlying asset\r\n     */\r\n\r\n    function rewardCollectThreshold() external view returns (uint256);\r\n\r\n    function underlyingNativePriceOracle() external view returns (address);\r\n\r\n    function setUnderlyingNativePriceOracle(address addr) external;\r\n\r\n    /**\r\n     * @dev Setter function for Rho token redemption fee\r\n     */\r\n    function setRedeemFee(uint256 _feeInBps) external;\r\n\r\n    /**\r\n     * @dev set the threshold for collect reward (denominated in underlying asset)\r\n     */\r\n    function setRewardCollectThreshold(uint256 _rewardCollectThreshold) external;\r\n\r\n    function setManagementFee(uint256 _feeInBps) external;\r\n\r\n    /**\r\n     * @dev set the allocation threshold (denominated in underlying asset)\r\n     */\r\n    function setReserveBoundary(uint256 _lowerBound, uint256 _upperBound) external;\r\n\r\n    /**\r\n     * @dev Setter function for minting fee (in bps)\r\n     */\r\n    function setMintingFee(uint256 _feeInBps) external;\r\n\r\n    function reserveLowerBound(uint256 tvl) external view returns (uint256);\r\n\r\n    function reserveUpperBound(uint256 tvl) external view returns (uint256);\r\n\r\n    function supplyRate() external view returns (uint256);\r\n\r\n    /**\r\n     * @dev Add strategy contract which implments the IRhoStrategy interface to the vault\r\n     */\r\n    function addStrategy(string memory name, address strategy) external;\r\n\r\n    /**\r\n     * @dev Remove strategy contract which implments the IRhoStrategy interface from the vault\r\n     */\r\n    function removeStrategy(address strategy) external;\r\n\r\n    /**\r\n     * @dev Check if a strategy is registered\r\n     * @param s address of strategy contract\r\n     * @return boolean\r\n     */\r\n    function isStrategyRegistered(address s) external view returns (bool);\r\n\r\n    function getStrategiesList() external view returns (Strategy[] memory);\r\n\r\n    function getStrategiesListLength() external view returns (uint256);\r\n\r\n    function updateStrategiesDetail(uint256 vaultUnderlyingBalance)\r\n        external\r\n        returns (\r\n            uint256[] memory,\r\n            uint256[] memory,\r\n            bool[] memory,\r\n            uint256,\r\n            uint256\r\n        );\r\n\r\n    function checkStrategiesCollectReward() external view returns (bool[] memory collectList);\r\n\r\n    function indicativeSupplyRate() external view returns (uint256);\r\n\r\n    function setFlurryToken(address addr) external;\r\n\r\n    function flurryStakingRewards() external view returns (address);\r\n\r\n    function setFlurryStakingRewards(address addr) external;\r\n\r\n    function tokenExchange() external view returns (address);\r\n\r\n    function setTokenExchange(address addr) external;\r\n\r\n    /**\r\n     * @notice Part of the management fee is used to buy back FLURRY\r\n     * from AMM. The FLURRY tokens are sent to FlurryStakingRewards\r\n     * to replendish the rewards pool.\r\n     * @return ratio of repurchasing, with 1e18 representing 100%\r\n     */\r\n    function repurchaseFlurryRatio() external view returns (uint256);\r\n\r\n    /**\r\n     * @notice setter method for `repurchaseFlurryRatio`\r\n     * @param _ratio new ratio to be set, must be <=1e18\r\n     */\r\n    function setRepurchaseFlurryRatio(uint256 _ratio) external;\r\n\r\n    /**\r\n     * @notice Triggers FLURRY repurchasing if management fee >= threshold\r\n     * @return threshold for triggering FLURRY repurchasing\r\n     */\r\n    function repurchaseFlurryThreshold() external view returns (uint256);\r\n\r\n    /**\r\n     * @notice setter method for `repurchaseFlurryThreshold`\r\n     * @param _threshold new threshold to be set\r\n     */\r\n    function setRepurchaseFlurryThreshold(uint256 _threshold) external;\r\n\r\n    /**\r\n     * @dev Vault should call this before repurchaseFlurry() for sanity check\r\n     * @return true if all dependent contracts are valid\r\n     */\r\n    function repurchaseSanityCheck() external view returns (bool);\r\n}\r\n"
    },
    "contracts/interfaces/IRhoStrategy.sol": {
      "content": "//SPDX-License-Identifier: MIT\r\npragma solidity 0.8.4;\r\nimport \"@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol\";\r\n\r\n/**\r\n * @title RhoStrategy Interface\r\n * @notice Interface for yield farming strategies to integrate with various DeFi Protocols like Compound, Aave, dYdX.. etc\r\n */\r\ninterface IRhoStrategy {\r\n    /**\r\n     * Events\r\n     */\r\n    event WithdrawAllCashAvailable();\r\n    event WithdrawUnderlying(uint256 amount);\r\n    event Deploy(uint256 amount);\r\n    event StrategyOutOfCash(uint256 balance, uint256 withdrawable);\r\n    event BalanceOfUnderlyingChanged(uint256 balance);\r\n\r\n    /**\r\n     * @return name of protocol\r\n     */\r\n    function NAME() external view returns (string memory);\r\n\r\n    /**\r\n     * @dev for conversion bwtween APY and per block rate\r\n     * @return number of blocks per year\r\n     */\r\n    function BLOCK_PER_YEAR() external view returns (uint256);\r\n\r\n    /**\r\n     * @dev setter function for `BLOCK_PER_YEAR`\r\n     * @param blocksPerYear new number of blocks per year\r\n     */\r\n    function setBlocksPerYear(uint256 blocksPerYear) external;\r\n\r\n    /**\r\n     * @return underlying ERC20 token\r\n     */\r\n    function underlying() external view returns (IERC20MetadataUpgradeable);\r\n\r\n    /**\r\n     * @dev unlock when TVL exceed the this target\r\n     */\r\n    function switchingLockTarget() external view returns (uint256);\r\n\r\n    /**\r\n     * @dev duration for locking the strategy\r\n     */\r\n    function switchLockDuration() external view returns (uint256);\r\n\r\n    /**\r\n     * @return block number after which rewards are unlocked\r\n     */\r\n    function switchLockedUntil() external view returns (uint256);\r\n\r\n    /**\r\n     * @dev setter of switchLockDuration\r\n     */\r\n    function setSwitchLockDuration(uint256 durationInBlock) external;\r\n\r\n    /**\r\n     * @dev lock the strategy with a lock target\r\n     */\r\n    function switchingLock(uint256 lockTarget, bool extend) external;\r\n\r\n    /**\r\n     * @dev view function to return balance in underlying\r\n     * @return balance (interest included) from DeFi protocol, in terms of underlying (in wei)\r\n     */\r\n    function balanceOfUnderlying() external view returns (uint256);\r\n\r\n    /**\r\n     * @dev updates the balance in underlying, and returns it. An `BalanceOfUnderlyingChanged` event is also emitted\r\n     * @return updated balance (interest included) from DeFi protocol, in terms of underlying (in wei)\r\n     */\r\n    function updateBalanceOfUnderlying() external returns (uint256);\r\n\r\n    /**\r\n     * @dev deploy the underlying to DeFi platform\r\n     * @param _amount amount of underlying (in wei) to deploy\r\n     */\r\n    function deploy(uint256 _amount) external;\r\n\r\n    /**\r\n     * @notice current supply rate per block excluding bonus token (such as Aave / Comp)\r\n     * @return supply rate per block, excluding yield from reward token if any\r\n     */\r\n    function supplyRatePerBlock() external view returns (uint256);\r\n\r\n    /**\r\n     * @notice current supply rate excluding bonus token (such as Aave / Comp)\r\n     * @return supply rate per year, excluding yield from reward token if any\r\n     */\r\n    function supplyRate() external view returns (uint256);\r\n\r\n    /**\r\n     * @return address of bonus token contract, or 0 if no bonus token\r\n     */\r\n    function bonusToken() external view returns (address);\r\n\r\n    /**\r\n     * @notice current bonus rate per block for bonus token (such as Aave / Comp)\r\n     * @return bonus supply rate per block\r\n     */\r\n    function bonusRatePerBlock() external view returns (uint256);\r\n\r\n    /**\r\n     * @return bonus tokens accrued\r\n     */\r\n    function bonusTokensAccrued() external view returns (uint256);\r\n\r\n    /**\r\n     * @notice current bonus supply rate (such as Aave / Comp)\r\n     * @return bonus supply rate per year\r\n     */\r\n    function bonusSupplyRate() external view returns (uint256);\r\n\r\n    /**\r\n     * @notice effective supply rate of the RhoStrategy\r\n     * @dev returns the effective supply rate fomr the underlying DeFi protocol\r\n     * taking into account any rewards tokens\r\n     * @return supply rate per year, including yield from reward token if any (in wei)\r\n     */\r\n    function effectiveSupplyRate() external view returns (uint256);\r\n\r\n    /**\r\n     * @notice effective supply rate of the RhoStrategy\r\n     * @dev returns the effective supply rate fomr the underlying DeFi protocol\r\n     * taking into account any rewards tokens AND the change in deployed amount.\r\n     * @param delta magnitude of underlying to be deployed / withdrawn\r\n     * @param isPositive true if `delta` is deployed, false if `delta` is withdrawn\r\n     * @return supply rate per year, including yield from reward token if any (in wei)\r\n     */\r\n    function effectiveSupplyRate(uint256 delta, bool isPositive) external view returns (uint256);\r\n\r\n    /**\r\n     * @dev Withdraw the amount in underlying from DeFi protocol and transfer to vault\r\n     * @param _amount amount of underlying (in wei) to withdraw\r\n     */\r\n    function withdrawUnderlying(uint256 _amount) external;\r\n\r\n    /**\r\n     * @dev Withdraw all underlying from DeFi protocol and transfer to vault\r\n     */\r\n    function withdrawAllCashAvailable() external;\r\n\r\n    /**\r\n     * @dev Collect any bonus reward tokens available for the strategy\r\n     */\r\n    function collectRewardToken() external;\r\n\r\n    /**\r\n     * @dev admin function - withdraw random token transfer to this contract\r\n     */\r\n    function sweepERC20Token(address token, address to) external;\r\n\r\n    function isLocked() external view returns (bool);\r\n\r\n    /**\r\n     * @notice Set the threshold (denominated in reward tokens) over which rewards tokens will automatically\r\n     * be converted into the underlying asset\r\n     * @dev default returns false. Override if the Protocol offers reward token (e.g. COMP for Compound)\r\n     * @param rewardCollectThreshold minimum threshold for collecting reward token\r\n     * @return true if reward in underlying > `rewardCollectThreshold`, false otherwise\r\n     */\r\n    function shouldCollectReward(uint256 rewardCollectThreshold) external view returns (bool);\r\n\r\n    /**\r\n     * @notice not all of the funds deployed to a strategy might be available for withdrawal\r\n     * @return the amount of underlying tokens available for withdrawal from the rho strategy\r\n     */\r\n    function underlyingWithdrawable() external view returns (uint256);\r\n}\r\n"
    },
    "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\nimport \"../IERC20Upgradeable.sol\";\n\n/**\n * @dev Interface for the optional metadata functions from the ERC20 standard.\n *\n * _Available since v4.1._\n */\ninterface IERC20MetadataUpgradeable is IERC20Upgradeable {\n    /**\n     * @dev Returns the name of the token.\n     */\n    function name() external view returns (string memory);\n\n    /**\n     * @dev Returns the symbol of the token.\n     */\n    function symbol() external view returns (string memory);\n\n    /**\n     * @dev Returns the decimals places of the token.\n     */\n    function decimals() external view returns (uint8);\n}\n"
    },
    "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\n/**\n * @dev Interface of the ERC20 standard as defined in the EIP.\n */\ninterface IERC20Upgradeable {\n    /**\n     * @dev Returns the amount of tokens in existence.\n     */\n    function totalSupply() external view returns (uint256);\n\n    /**\n     * @dev Returns the amount of tokens owned by `account`.\n     */\n    function balanceOf(address account) external view returns (uint256);\n\n    /**\n     * @dev Moves `amount` tokens from the caller's account to `recipient`.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * Emits a {Transfer} event.\n     */\n    function transfer(address recipient, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Returns the remaining number of tokens that `spender` will be\n     * allowed to spend on behalf of `owner` through {transferFrom}. This is\n     * zero by default.\n     *\n     * This value changes when {approve} or {transferFrom} are called.\n     */\n    function allowance(address owner, address spender) external view returns (uint256);\n\n    /**\n     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * IMPORTANT: Beware that changing an allowance with this method brings the risk\n     * that someone may use both the old and the new allowance by unfortunate\n     * transaction ordering. One possible solution to mitigate this race\n     * condition is to first reduce the spender's allowance to 0 and set the\n     * desired value afterwards:\n     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729\n     *\n     * Emits an {Approval} event.\n     */\n    function approve(address spender, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Moves `amount` tokens from `sender` to `recipient` using the\n     * allowance mechanism. `amount` is then deducted from the caller's\n     * allowance.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * Emits a {Transfer} event.\n     */\n    function transferFrom(\n        address sender,\n        address recipient,\n        uint256 amount\n    ) external returns (bool);\n\n    /**\n     * @dev Emitted when `value` tokens are moved from one account (`from`) to\n     * another (`to`).\n     *\n     * Note that `value` may be zero.\n     */\n    event Transfer(address indexed from, address indexed to, uint256 value);\n\n    /**\n     * @dev Emitted when the allowance of a `spender` for an `owner` is set by\n     * a call to {approve}. `value` is the new allowance.\n     */\n    event Approval(address indexed owner, address indexed spender, uint256 value);\n}\n"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 1000
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    },
    "libraries": {}
  }
}}