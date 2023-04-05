// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {Swap} from "src/Swap.sol";

contract SwapTest is Test {
    Swap internal swap;

    // hardcode addresses from polygon mainnet for forktesting
    // this way it's only possible to test against a fork, not unit
    address internal constant quickswap = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address internal constant sushiswap = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address internal constant weth = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address internal constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    //Utils internal utils;
    address payable[] internal users;
    address internal account0;

    function setUp() public {
        swap = new Swap();
        account0 = address(100);
        vm.label(account0, "Account 0");
    }
    
    function testTransferETH() public {
    
    //function testGetAmountOutMin() public {
        //uint256 amount = 1 ether;
        //arbitrage.getAmountOutMin({router: quickswap, tokenIn: weth, tokenOut: usdc, amount: amount});
    //}

    //function testEstimateTrade() public {
        //uint256 amount = 1 ether;
        //arbitrage.estimateTrade({router1: quickswap, router2: sushiswap, token1: weth, token2: usdc, amount: amount});
    //}
}

