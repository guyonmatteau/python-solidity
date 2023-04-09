// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@sushiswap/sushiswap/protocols/sushiswap/contracts/interfaces/IUniswapV2Router02.sol";

contract Swap is Ownable {
    function swapUniV2(address _router, address tokenIn, address tokenOut, uint256 amount) external returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        IUniswapV2Router02 uni = IUniswapV2Router02(_router);
        IERC20(tokenIn).approve(address(_router), amount);

        uint256[] memory amountsOut = uni.getAmountsOut(amount, path);

        uint256 amountOut = amountsOut[path.length - 1];

        uint256[] memory amounts = uni.swapTokensForExactTokens({
            amountOut: amountOut,
            amountInMax: 2 gwei,
            path: path,
            to: address(this),
            deadline: block.timestamp + 60000
        });

        return amounts[path.length - 1];
    }

    // @dev transfer method required to deposit into WETH contract

    function transferETH(address to, uint256 amount) external onlyOwner {
        // this is already done by the deposit method
        // IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // TODO add reentrancy safeguard
        (bool success,) = to.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    // @dev swap amountIn of tokenIn for tokenOut using UniswapV3 router interface
    function swap(address _router, address tokenIn, address tokenOut, uint24 poolFee, uint256 amountIn)
        external
        onlyOwner
        returns (uint256 amountOut)
    {
        require(IERC20(tokenIn).balanceOf(address(this)) >= amountIn, "Insufficient tokens to perform swap");

        // instantiate UniSwapV3 router
        ISwapRouter router = ISwapRouter(_router);
        IERC20(tokenIn).approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // do actual swap
        amountOut = router.exactInputSingle(params);
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
