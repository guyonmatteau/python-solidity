// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Assembly {
    function f(uint n) public pure returns (uint) {
        assembly {
            if eq(n, 0) {
                // return 0 if n == 0
                mstore(0, 0)
                return(0, 32)
            }
            if eq(n, 1) {
                // return 1 if n == 1
                mstore(0, 1)
                return(0, 32)
            }
            let prev := 0
            let curr := 1
            for { let i := 2 } lt(i, add(n, 1)) { i := add(i, 1) } {
                let temp := curr
                curr := add(curr, prev)
                prev := temp
            }
            mstore(0, curr)
            return(0, 32)
        }
    }
}

