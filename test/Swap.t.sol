// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Swap} from "src/Swap.sol";

contract SwapTest is Test {
    Swap internal swap;

    // token address on mainnet
    address internal constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant uniswapv3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address internal constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // generate addresses for testing
    address internal contractDeployer = makeAddr("contractDeployer");

    function setUp() public {
        // deploy contract
        vm.prank(contractDeployer);
        swap = new Swap();

        // deposit funds to the contract to swap
        vm.deal(address(swap), 100 ether);
    }

    function testTransferETH() public {
        // WETH balance of Swap contract should be 0
        uint256 balance = IERC20(weth).balanceOf(address(swap));
        assertEq(balance, 0, "WETH balance of Swap contract not zero pre-transfer");

        // swap ETH to WETH by transfering ETH
        vm.prank(contractDeployer);
        swap.transferETH({to: weth, amount: 1 ether});
        uint256 wethBalance = IERC20(weth).balanceOf(address(swap));

        // assert that ETH was transferred
        assertFalse(wethBalance == 0);
        assertFalse(address(swap).balance == 10 ether);
        console.log("Swap contract WETH balance post transfer: %s", wethBalance);
    }

    function testSwap() public {
        // swap ETH to WETH by transfering ETH
        vm.prank(contractDeployer);
        swap.transferETH({to: weth, amount: 10 ether});
        uint256 wethBalance = IERC20(weth).balanceOf(address(swap));

        // USDC balance of Swap contract should be 0 pre-swap
        uint256 usdcBalance = IERC20(usdc).balanceOf(address(swap));
        assertEq(usdcBalance, 0, "USDC balance of Swap contract not zero pre-swap");

        // perform swapj
        vm.prank(contractDeployer);
        uint256 tokensOut =
            swap.swap({_router: uniswapv3, tokenIn: weth, tokenOut: usdc, poolFee: 3000, amountIn: 1 ether});

        // assert that WETH was properly swapped for USDC
        uint256 newUSDCBalance = IERC20(usdc).balanceOf(address(swap));
        assertFalse(newUSDCBalance == 0, "USDC balance still zero post-swap");

        console.log("USDC balance post swap: %s", tokensOut);
    }

    //function testGetAmountOutMin() public {
    //uint256 amount = 1 ether;
    //arbitrage.getAmountOutMin({router: quickswap, tokenIn: weth, tokenOut: usdc, amount: amount});
    //}

    //function testEstimateTrade() public {
    //uint256 amount = 1 ether;
    //arbitrage.estimateTrade({router1: quickswap, router2: sushiswap, token1: weth, token2: usdc, amount: amount});
    //}
}
