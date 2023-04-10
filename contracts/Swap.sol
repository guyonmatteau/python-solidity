// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@sushiswap/sushiswap/protocols/sushiswap/contracts/interfaces/IUniswapV2Router02.sol";

using SafeERC20 for IERC20;

contract Swap is Ownable {
    // @dev transfer method required to deposit into WETH contract
    function transfer(address to, uint256 amount) external onlyOwner {
        // TODO add reentrancy safeguard
        (bool success,) = to.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawERC20(address token, uint256 amount) external onlyOwner {
        transferERC20({token: token, recipient: address(this), amount: amount});
    }

    // @dev get ERC20 token balance of Swap contract
    function getTokenBalance(address tokenAddress) external view returns (uint256) {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        return balance;
    }

    function transferERC20(address token, address recipient, uint256 amount) public onlyOwner {
        // USDT is a non-standard ERC20 token so need to use the safe library
        IERC20(token).safeTransfer({to: recipient, value: amount});
    }

    receive() external payable {}

    function swapUniV2(address _router, address tokenIn, address tokenOut, uint256 amount) external returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        IUniswapV2Router02 router = IUniswapV2Router02(_router);
        IERC20(tokenIn).approve(address(router), amount);

        uint256[] memory amountsOut = router.getAmountsOut(amount, path);
        uint256 amountOut = amountsOut[path.length - 1];

        // do actual swap
        uint256[] memory amounts = router.swapTokensForExactTokens({
            amountOut: amountOut,
            amountInMax: 2 gwei,
            path: path,
            to: address(this),
            deadline: block.timestamp + 60000
        });

        return amounts[path.length - 1];
    }

    // @dev swap amountIn of tokenIn for tokenOut using UniswapV3 router interface
    function swapUniV3(address _router, address tokenIn, address tokenOut, uint24 poolFee, uint256 amountIn)
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
}
