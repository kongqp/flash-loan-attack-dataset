// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";

import "../libraries/SafeBEP20.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IMasterApe.sol";
import "./VaultController.sol";
import {PoolConstant} from "../libraries/PoolConstant.sol";

contract AutoCake is VaultController, IStrategy {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;

    address private initializer;

    address private constant SPACE_TOKEN = 0xe486a69E432Fdc29622bF00315f6b34C99b45e80;
    IBEP20 private constant CAKE = IBEP20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    IBEP20 private constant WBNB = IBEP20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IMasterApe private constant MASTERCHEF = IMasterApe(0x73feaa1eE314F8c655E354234017bE2193C9E24E);

    uint256 public constant override pid = 0;
    PoolConstant.PoolTypes public constant override poolType = PoolConstant.PoolTypes.BananaStake; // legacy attribute

    uint256 private constant DUST = 1000;

    IApeRouter02 public ROUTER = IApeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address[] path;

    uint256 public totalShares;
    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _principal;
    mapping(address => uint256) private _depositedAt;

    modifier onlyInitializer {
        require(initializer != address(0), "AutoCake::Already initialized");
        require(initializer == owner(), "AutoCake::Not the owner");
        _;
    }

    constructor() public VaultController(CAKE, SPACE_TOKEN) {
        initializer = msg.sender;
        path = new address[](2);
        path[0] = address(CAKE);
        path[1] = address(WBNB);
    }

    function initialize(address minter) external onlyInitializer {
        CAKE.safeApprove(address(ROUTER), uint256(~0));
        CAKE.safeApprove(address(MASTERCHEF), uint256(~0));

        setMinter(minter);
        WBNB.safeApprove(minter, uint256(~0));

        initializer = address(0);
    }

    function totalSupply() external view override returns (uint256) {
        return totalShares;
    }

    function balance() public view override returns (uint256) {
        (uint256 amount, ) = MASTERCHEF.userInfo(pid, address(this));
        return CAKE.balanceOf(address(this)).add(amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (totalShares == 0) return 0;
        return balance().mul(sharesOf(account)).div(totalShares);
    }

    function withdrawableBalanceOf(address account) public view override returns (uint256) {
        return balanceOf(account);
    }

    function sharesOf(address account) public view override returns (uint256) {
        return _shares[account];
    }

    function principalOf(address account) public view override returns (uint256) {
        return _principal[account];
    }

    function earned(address account) public view override returns (uint256) {
        if (balanceOf(account) >= principalOf(account) + DUST) {
            return balanceOf(account).sub(principalOf(account));
        } else {
            return 0;
        }
    }

    function priceShare() external view override returns (uint256) {
        if (totalShares == 0) return 1e18;
        return balance().mul(1e18).div(totalShares);
    }

    function depositedAt(address account) external view override returns (uint256) {
        return _depositedAt[account];
    }

    function rewardsToken() external view override returns (address) {
        return address(_stakingToken);
    }

    function deposit(uint256 _amount) public override {
        _deposit(_amount, msg.sender);

        if (isWhitelist(msg.sender) == false) {
            _principal[msg.sender] = _principal[msg.sender].add(_amount);
            _depositedAt[msg.sender] = block.timestamp;
        }
    }

    function depositAll() external override {
        deposit(CAKE.balanceOf(msg.sender));
    }

    function withdrawAll() external override {
        uint256 amount = balanceOf(msg.sender);
        uint256 principal = principalOf(msg.sender);
        uint256 depositTimestamp = _depositedAt[msg.sender];

        totalShares = totalShares.sub(_shares[msg.sender]);
        delete _shares[msg.sender];
        delete _principal[msg.sender];
        delete _depositedAt[msg.sender];

        _withdrawTokenWithCorrection(amount);

        uint256 profit = amount > principal ? amount.sub(principal) : 0;
        uint256 withdrawalFee = canMint() ? _minter.withdrawalFee(principal, depositTimestamp) : 0;
        uint256 performanceFee = canMint() ? _minter.performanceFee(profit) : 0;

        if (withdrawalFee.add(performanceFee) > DUST) {
            uint256 convertedAssets = convert(withdrawalFee.add(performanceFee));
            _minter.mintFor(address(WBNB), 0, convertedAssets, msg.sender, depositTimestamp);
            if (performanceFee > 0) {
                emit ProfitPaid(msg.sender, profit, performanceFee);
            }
            amount = amount.sub(withdrawalFee).sub(performanceFee);
        }

        CAKE.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);

        _harvest();
    }

    function harvest() external override {
        MASTERCHEF.leaveStaking(0);
        _harvest();
    }

    function withdraw(uint256 shares) external override onlyWhitelisted {
        uint256 amount = balance().mul(shares).div(totalShares);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);

        _withdrawTokenWithCorrection(amount);
        CAKE.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, 0);

        _harvest();
    }

    // @dev underlying only + withdrawal fee + no perf fee
    function withdrawUnderlying(uint256 _amount) external {
        uint256 amount = Math.min(_amount, _principal[msg.sender]);
        uint256 shares = Math.min(amount.mul(totalShares).div(balance()), _shares[msg.sender]);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);
        _principal[msg.sender] = _principal[msg.sender].sub(amount);

        _withdrawTokenWithCorrection(amount);
        uint256 depositTimestamp = _depositedAt[msg.sender];
        uint256 withdrawalFee = canMint() ? _minter.withdrawalFee(amount, depositTimestamp) : 0;
        if (withdrawalFee > DUST) {
            uint256 convertedAssets = convert(withdrawalFee);
            _minter.mintFor(address(WBNB), convertedAssets, 0, msg.sender, depositTimestamp);
            amount = amount.sub(withdrawalFee);
        }

        CAKE.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);

        _harvest();
    }

    function getReward() external override {
        uint256 amount = earned(msg.sender);
        uint256 shares = Math.min(amount.mul(totalShares).div(balance()), _shares[msg.sender]);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);
        _cleanupIfDustShares();

        _withdrawTokenWithCorrection(amount);
        uint256 depositTimestamp = _depositedAt[msg.sender];
        uint256 performanceFee = canMint() ? _minter.performanceFee(amount) : 0;
        if (performanceFee > DUST) {
            uint256 convertedAssets = convert(performanceFee);
            _minter.mintFor(address(WBNB), 0, convertedAssets, msg.sender, depositTimestamp);
            amount = amount.sub(performanceFee);
        }

        CAKE.safeTransfer(msg.sender, amount);
        emit ProfitPaid(msg.sender, amount, performanceFee);

        _harvest();
    }

    // Private functions
    function _harvest() private {
        uint256 cakeAmount = CAKE.balanceOf(address(this));
        if (cakeAmount > 0) {
            emit Harvested(cakeAmount);
            MASTERCHEF.enterStaking(cakeAmount);
        }
    }

    function _deposit(uint256 _amount, address _to) private notPaused {
        uint256 _pool = balance();
        CAKE.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 shares = 0;
        if (totalShares == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalShares)).div(_pool);
        }

        totalShares = totalShares.add(shares);
        _shares[_to] = _shares[_to].add(shares);

        MASTERCHEF.enterStaking(_amount);
        emit Deposited(msg.sender, _amount);

        _harvest();
    }

    function _withdrawTokenWithCorrection(uint256 amount) private {
        uint256 cakeBalance = CAKE.balanceOf(address(this));
        if (cakeBalance < amount) {
            MASTERCHEF.leaveStaking(amount.sub(cakeBalance));
        }
    }

    function _cleanupIfDustShares() private {
        uint256 shares = _shares[msg.sender];
        if (shares > 0 && shares < DUST) {
            totalShares = totalShares.sub(shares);
            delete _shares[msg.sender];
        }
    }

    function convert(uint256 amount) internal returns (uint256) {
        require(amount > 0, "AutoCake:: Amount can't be equal to zero");
        require(CAKE.balanceOf(address(this)) >= amount, "AutoCake::Insuficient Balance");

        _approveTokenIfNeeded();
        uint256[] memory amounts = ROUTER.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _approveTokenIfNeeded() private {
        if (CAKE.allowance(address(this), address(ROUTER)) == 0) {
            CAKE.safeApprove(address(ROUTER), uint256(~0));
        }
    }

    // Emergency only
    function recoverToken(address token, uint256 amount) external override onlyOwner {
        IBEP20(token).safeTransfer(owner(), amount);
    }
}
