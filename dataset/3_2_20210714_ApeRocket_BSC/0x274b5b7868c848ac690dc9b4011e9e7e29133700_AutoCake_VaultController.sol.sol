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

import "../libraries/SafeBEP20.sol";
import "../libraries/BEP20.sol";

import "../interfaces/IApeRouter02.sol";
import "../interfaces/IApePair.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/ISpaceMinter.sol";
import "../interfaces/ISpaceChef.sol";
import "../libraries/Pausable.sol";
import "../libraries/Whitelist.sol";

abstract contract VaultController is IVaultController, Pausable, Whitelist {
    using SafeBEP20 for IBEP20;

    BEP20 public SPACE;

    address public keeper;

    IBEP20 internal _stakingToken;
    ISpaceMinter internal _minter;
    ISpaceChef internal _spaceChef;

    event Recovered(address token, uint256 amount);

    modifier onlyKeeper {
        require(msg.sender == keeper || msg.sender == owner(), "VaultController: caller is not the owner or keeper");
        _;
    }

    constructor(IBEP20 token, address _SPACE) public {
        keeper = msg.sender;
        SPACE = BEP20(_SPACE);
        _stakingToken = token;
    }

    function minter() external view override returns (address) {
        return canMint() ? address(_minter) : address(0);
    }

    function canMint() internal view returns (bool) {
        return address(_minter) != address(0) && _minter.isMinter(address(this));
    }

    function spaceChef() external view override returns (address) {
        return address(_spaceChef);
    }

    function stakingToken() external view override returns (address) {
        return address(_stakingToken);
    }

    // Only owner
    function setKeeper(address _keeper) external onlyKeeper {
        require(_keeper != address(0), "VaultController: invalid keeper address");
        keeper = _keeper;
    }

    function setMinter(address newMinter) public virtual onlyOwner {
        // can zero
        _minter = ISpaceMinter(newMinter);
        if (newMinter != address(0)) {
            require(newMinter == SPACE.getOwner(), "VaultController: not space minter");
            _stakingToken.safeApprove(newMinter, 0);
            _stakingToken.safeApprove(newMinter, uint256(~0));
        }
    }

    function setSpaceChef(ISpaceChef newSpaceChef) public virtual onlyOwner {
        require(address(_spaceChef) == address(0), "VaultController: setSpaceChef only once");
        _spaceChef = newSpaceChef;
    }

    // Emergency only
    function recoverToken(address _token, uint256 amount) external virtual onlyOwner {
        require(_token != address(_stakingToken), "VaultController: cannot recover underlying token");
        IBEP20(_token).safeTransfer(owner(), amount);

        emit Recovered(_token, amount);
    }
}
