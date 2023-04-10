// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Fibonacci {
    function calculateFibonacci(uint256 n) public pure returns (uint256) {
        if (n == 0) return 0;
        uint256 a = 0;
        uint256 b = 1;
        for (uint256 i = 2; i <= n; i++) {
            uint256 c = a + b;
            a = b;
            b = c;
        }
        return b;
    }
}
