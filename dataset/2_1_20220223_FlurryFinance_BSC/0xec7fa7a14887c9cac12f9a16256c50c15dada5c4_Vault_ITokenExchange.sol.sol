//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "./IPriceOracle.sol";

/**
 * @title Token Exchange Interface
 * @notice Interface for exchanging token on other protocols such as uniswap
 *
 */
interface ITokenExchange {
    event SellToken(address inputToken, address outputToken, uint256 amountIn, uint256 amountOut);

    /**
     * @notice A method to sell input token into output token for a certain input amount.
     * @return uint256 ouptut token received
     */
    function sellExactInput(
        IERC20MetadataUpgradeable inputToken,
        IERC20MetadataUpgradeable outputToken,
        address recipient,
        uint256 amountIn_
    ) external returns (uint256);
}
