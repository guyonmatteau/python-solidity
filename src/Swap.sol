// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

/*
Contract requirements
1. Able to receive ETH and tokens from address owner
2. Owner should be able to withdraw any ERC20 and ETH.
3. Swap ETH - USDC on Uniswap V3
4. Swap output for USDT on Sushiswap
5. Send output to EOA.
*/

contract Swap is Ownable {
    function getAmountOutMin(address router, address tokenIn, address tokenOut, uint256 amount)
        public
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256[] memory amountsOut = IUniswapV2Router02(router).getAmountsOut(amount, path);

        return amountsOut[path.length - 1];
    }

    // @dev Estimate potential trade
    function estimateTrade(address router1, address router2, address token1, address token2, uint256 amount)
        external
        view
        returns (uint256)
    {
        uint256 amount1 = getAmountOutMin(router1, token1, token2, amount);
        uint256 amount2 = getAmountOutMin(router2, token2, token1, amount1);
        return amount2;
    }

    // swap v3
    // https://uniswapv3book.com/docs/milestone_5/swap-fees/
    function swap(address _router, address tokenIn, address tokenOut, uint24 poolFee, uint256 amountIn)
        external
        returns (uint256 amountOut)
    {
        ISwapRouter router = ISwapRouter(_router);

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: poolFee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        amountOut = router.exactInputSingle(params);
    }

    // @dev transfer method required to deposit into WETH contract
    function transferETH(address to, uint256 amount) external onlyOwner {
       payable(to).transfer(amount);
    }

    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawERC20(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).transferFrom({from: address(this), to: msg.sender, amount: amount});
    }

    // @dev get ERC20 token balance of Arbitrage contract
    function getTokenBalance(address tokenAddress) external view returns (uint256) {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        return balance;
    }

    receive() external payable {}
}
