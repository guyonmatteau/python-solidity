// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Swap} from "contracts/Swap.sol";

contract SwapTest is Test {
    Swap internal swap;

    // routers on mainnet
    address internal constant uniswapv3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564; // validated for UniV3
    address internal constant uniswapv2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // validated for UniV2
    address internal constant sushiswap = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; // validated SushiSwapRouter

    // ERC20s on mainnet
    address internal constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

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
        swap.transfer({to: weth, amount: 1 ether});
        uint256 wethBalance = IERC20(weth).balanceOf(address(swap));

        // assert that ETH was transferred
        assertFalse(wethBalance == 0);
        assertFalse(address(swap).balance == 10 ether);
        console.log("Contract WETH balance post transfer: %s", wethBalance);
    }

    function testSwapUniV3() public {
        // swap ETH to WETH by transfering ETH
        vm.prank(contractDeployer);
        swap.transfer({to: weth, amount: 10 ether});
        uint256 wethBalance = IERC20(weth).balanceOf(address(swap));
        console.log("Contract WETH balance pre Uniswap", wethBalance);

        // USDC balance of Swap contract should be 0 pre-swap
        uint256 usdcBalance = IERC20(usdc).balanceOf(address(swap));
        assertEq(usdcBalance, 0, "USDC balance of Swap contract not zero pre-swap");

        // perform swap
        vm.prank(contractDeployer);
        uint256 tokensOut =
            swap.swapUniV3({_router: uniswapv3, tokenIn: weth, tokenOut: usdc, poolFee: 3000, amountIn: 1 ether});

        // assert that WETH was properly swapped for USDC
        uint256 newUSDCBalance = IERC20(usdc).balanceOf(address(swap));
        assertFalse(newUSDCBalance == 0, "USDC balance still zero post-swap");

        console.log("Contract USDC balance post UniSwap: %s", tokensOut);
    }

    // swap USDC for USDT
    function testSwapUniV2() public {
        // setup some USDC for the contract
        testSwapUniV3();

        uint256 usdcBalance = IERC20(usdc).balanceOf(address(swap));
        console.log("Contract USDC balance pre SushiSwap", usdcBalance);

        // check initial condition that USDT balance is zero pre swap
        uint256 usdtBalance = IERC20(usdt).balanceOf(address(swap));
        assertEq(usdtBalance, 0, "USDT balance of Swap contract not zero pre-swap");

        // swap usdc for usdt. USDC denotes its value in 6 decimals, so if we pick 1 gwei = 1e9 wei = 1000$
        vm.prank(contractDeployer);
        uint256 tokensOut = swap.swapUniV2({_router: sushiswap, tokenIn: usdc, tokenOut: usdt, amount: usdcBalance});
        console.log("SushiSwap tokensOut: %s", tokensOut);

        // check initial condition that USDT balance is zero pre swap
        uint256 newUSDTBalance = IERC20(usdt).balanceOf(address(swap));
        assertFalse(newUSDTBalance == 0, "USDT balance still zero post-swap");
        console.log("Contract USDT balance post SushiSwap: %s", tokensOut);
    }

    function testTransferERC20() public {
        // make sure contract has UDST to transfer
        testSwapUniV2();

        uint256 contractUSDTBalance = IERC20(usdt).balanceOf(address(swap));
        assertFalse(contractUSDTBalance == 0);
        console.log("Contract USDT balance post SushiSwap", contractUSDTBalance);

        address recipient = makeAddr("recipient");
        assertEq(IERC20(usdt).balanceOf(recipient), 0, "ERC20 balance of recipient not zero pre transfer");
        // transfer USDT from contract to recipient
        vm.prank(contractDeployer);
        swap.transferERC20({token: usdt, recipient: recipient, amount: contractUSDTBalance});

        // check balance of recipient
        uint256 usdtBalancePostTransfer = IERC20(usdt).balanceOf(recipient);
        assertEq(usdtBalancePostTransfer, contractUSDTBalance, "Not all tokens were transferred");
        assertEq(IERC20(usdt).balanceOf(address(swap)), 0, "Not all USDT transferred");
        console.log("Recipient USDT balance post transfer", usdtBalancePostTransfer);
    }
}
