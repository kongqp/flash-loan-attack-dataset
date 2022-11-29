// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import {PoolConstant} from "../libraries/PoolConstant.sol";
import "../interfaces/IApeRouter02.sol";
import "../interfaces/IApePair.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IApeChef.sol";
import "../interfaces/ISpaceMinter.sol";
import "./Zap.sol";

import "./VaultController.sol";

contract VaultFlipToFlip is VaultController, IStrategy {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;

    IApeRouter02 private constant ROUTER =
        IApeRouter02(0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607);
    IBEP20 private constant BANANA =
        IBEP20(0x5d47bAbA0d66083C52009271faF3F50DCc01023C);
    IApeChef private APE_MASTER_CHEF;

    PoolConstant.PoolTypes public constant override poolType =
        PoolConstant.PoolTypes.FlipToFlip;

    Zap public zap;
    uint256 private constant DUST = 1000;

    uint256 public override pid;

    address private _token0;
    address private _token1;

    uint256 public totalShares;
    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _principal;
    mapping(address => uint256) private _depositedAt;

    uint256 public bananaHarvested;

    modifier updateBananaHarvested {
        uint256 before = BANANA.balanceOf(address(this));
        _;
        uint256 _after = BANANA.balanceOf(address(this));
        bananaHarvested = bananaHarvested.add(_after).sub(before);
    }

    function initialize(
        uint256 _pid,
        IBEP20 _token,
        address payable _zap
    ) external initializer {
        __VaultController_init(IBEP20(_token));
        APE_MASTER_CHEF = IApeChef(0x54aff400858Dcac39797a81894D9920f16972D1D);
        setFlipToken(address(_token));
        pid = _pid;
        zap = Zap(_zap);

        BANANA.approve(address(ROUTER), uint256(~0));
        BANANA.approve(_zap, uint256(~0));
    }

    function totalSupply() external view override returns (uint256) {
        return totalShares;
    }

    function balance() public view override returns (uint256 amount) {
        (amount, ) = APE_MASTER_CHEF.userInfo(pid, address(this));
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (totalShares == 0) return 0;
        return balance().mul(sharesOf(account)).div(totalShares);
    }

    function withdrawableBalanceOf(address account)
        public
        view
        override
        returns (uint256)
    {
        return balanceOf(account);
    }

    function sharesOf(address account) public view override returns (uint256) {
        return _shares[account];
    }

    function principalOf(address account)
        public
        view
        override
        returns (uint256)
    {
        return _principal[account];
    }

    function earned(address account) public view override returns (uint256) {
        if (balanceOf(account) >= principalOf(account) + DUST) {
            return balanceOf(account).sub(principalOf(account));
        } else {
            return 0;
        }
    }

    function depositedAt(address account)
        external
        view
        override
        returns (uint256)
    {
        return _depositedAt[account];
    }

    function rewardsToken() external view override returns (address) {
        return address(_stakingToken);
    }

    function priceShare() external view override returns (uint256) {
        if (totalShares == 0) return 1e18;
        return balance().mul(1e18).div(totalShares);
    }

    function deposit(uint256 _amount) public override {
        _depositTo(_amount, msg.sender);
    }

    function depositAll() external override {
        deposit(_stakingToken.balanceOf(msg.sender));
    }

    function withdrawAll() external override {
        uint256 amount = balanceOf(msg.sender);
        uint256 principal = principalOf(msg.sender);
        uint256 depositTimestamp = _depositedAt[msg.sender];

        totalShares = totalShares.sub(_shares[msg.sender]);
        delete _shares[msg.sender];
        delete _principal[msg.sender];
        delete _depositedAt[msg.sender];

        amount = _withdrawTokenWithCorrection(amount);
        uint256 profit = amount > principal ? amount.sub(principal) : 0;

        uint256 withdrawalFee = canMint()
            ? _minter.withdrawalFee(principal, depositTimestamp)
            : 0;
        uint256 performanceFee = canMint() ? _minter.performanceFee(profit) : 0;
        if (withdrawalFee.add(performanceFee) > DUST) {
            _minter.mintFor(
                address(_stakingToken),
                withdrawalFee,
                performanceFee,
                msg.sender,
                depositTimestamp
            );

            if (performanceFee > 0) {
                emit ProfitPaid(msg.sender, profit, performanceFee);
            }
            amount = amount.sub(withdrawalFee).sub(performanceFee);
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);
    }

    function harvest() external override onlyKeeper {
        _harvest();

        uint256 before = _stakingToken.balanceOf(address(this));
        zap.zapInToken(
            address(BANANA),
            bananaHarvested,
            address(_stakingToken)
        );
        uint256 harvested = _stakingToken.balanceOf(address(this)).sub(before);

        APE_MASTER_CHEF.deposit(pid, harvested, address(this));
        emit Harvested(harvested);

        bananaHarvested = 0;
    }

    function _harvest() private updateBananaHarvested {
        APE_MASTER_CHEF.harvest(pid, address(this));
    }

    function withdraw(uint256 shares) external override onlyWhitelisted {
        uint256 amount = balance().mul(shares).div(totalShares);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);

        amount = _withdrawTokenWithCorrection(amount);
        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, 0);
    }

    // @dev underlying only + withdrawal fee + no perf fee
    function withdrawUnderlying(uint256 _amount) external {
        uint256 amount = Math.min(_amount, _principal[msg.sender]);
        uint256 shares = Math.min(
            amount.mul(totalShares).div(balance()),
            _shares[msg.sender]
        );
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);
        _principal[msg.sender] = _principal[msg.sender].sub(amount);

        amount = _withdrawTokenWithCorrection(amount);
        uint256 depositTimestamp = _depositedAt[msg.sender];
        uint256 withdrawalFee = canMint()
            ? _minter.withdrawalFee(amount, depositTimestamp)
            : 0;
        if (withdrawalFee > DUST) {
            _minter.mintFor(
                address(_stakingToken),
                withdrawalFee,
                0,
                msg.sender,
                depositTimestamp
            );
            amount = amount.sub(withdrawalFee);
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);
    }

    // @dev profits only (underlying + space) + no withdraw fee + perf fee
    function getReward() external override {
        uint256 amount = earned(msg.sender);
        uint256 shares = Math.min(
            amount.mul(totalShares).div(balance()),
            _shares[msg.sender]
        );
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);
        _cleanupIfDustShares();

        amount = _withdrawTokenWithCorrection(amount);
        uint256 depositTimestamp = _depositedAt[msg.sender];
        uint256 performanceFee = canMint() ? _minter.performanceFee(amount) : 0;
        if (performanceFee > DUST) {
            _minter.mintFor(
                address(_stakingToken),
                0,
                performanceFee,
                msg.sender,
                depositTimestamp
            );
            amount = amount.sub(performanceFee);
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit ProfitPaid(msg.sender, amount, performanceFee);
    }

    // Private functions
    function setFlipToken(address _token) private {
        _token0 = IApePair(_token).token0();
        _token1 = IApePair(_token).token1();

        _stakingToken.safeApprove(address(APE_MASTER_CHEF), uint256(~0));
        IBEP20(_token0).safeApprove(address(ROUTER), uint256(~0));
        IBEP20(_token1).safeApprove(address(ROUTER), uint256(~0));
    }

    function _depositTo(uint256 _amount, address _to)
        private
        notPaused
        updateBananaHarvested
    {
        uint256 _pool = balance();
        uint256 _before = _stakingToken.balanceOf(address(this));
        _stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = _stakingToken.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint256 shares = 0;
        if (totalShares == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalShares)).div(_pool);
        }

        totalShares = totalShares.add(shares);
        _shares[_to] = _shares[_to].add(shares);
        _principal[_to] = _principal[_to].add(_amount);
        _depositedAt[_to] = block.timestamp;

        APE_MASTER_CHEF.deposit(pid, _amount, address(this));
        emit Deposited(_to, _amount);
    }

    function _withdrawTokenWithCorrection(uint256 amount)
        private
        updateBananaHarvested
        returns (uint256)
    {
        uint256 before = _stakingToken.balanceOf(address(this));
        APE_MASTER_CHEF.withdraw(pid, amount, address(this));
        return _stakingToken.balanceOf(address(this)).sub(before);
    }

    function _cleanupIfDustShares() private {
        uint256 shares = _shares[msg.sender];
        if (shares > 0 && shares < DUST) {
            totalShares = totalShares.sub(shares);
            delete _shares[msg.sender];
        }
    }

    // Emergency only
    // @dev stakingToken must not remain balance in this contract. So dev should salvage staking token transferred by mistake.
    function recoverToken(address token, uint256 amount)
        external
        override
        onlyOwner
    {
        if (token == address(BANANA)) {
            uint256 bananaBalance = BANANA.balanceOf(address(this));
            require(
                amount <= bananaBalance.sub(bananaHarvested),
                "VaultFlipToFlip: cannot recover lp's harvested banana"
            );
        }

        IBEP20(token).safeTransfer(owner(), amount);
        emit Recovered(token, amount);
    }

    function stakeTo(uint256 amount, address account) external override {}
}
