// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@sushiswap/sushiswap/protocols/sushiswap/contracts/interfaces/IUniswapV2Router02.sol";

contract Swap is Ownable {
    function swapUniV2(address _router, address tokenIn, address tokenOut, uint256 amount)
        external
        onlyOwner
        returns (uint256 amountOut)
    {
        uint256 amountOut = getAmountOutMin(_router, tokenIn, tokenOut, amount);
        return amountOut;
    }

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
