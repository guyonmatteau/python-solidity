// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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
