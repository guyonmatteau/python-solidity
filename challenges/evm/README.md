# EVM Challenge

This doc contains the approach for solving the EVM challenge.

## Problem statement and approach
_
What is the shortest runtime bytecode you can write for a contract that satisfies:
- Accept calldata of length 32 bytes representing one uint256 (no function selector);
- Returns, as one uint256, the Fibonacci number at the index of the input (the sequence can start at either 0 or 1).
_

The approach is to first find a solution for the problem in general and from there onwards improve. The problem states: the Fibonacci number at the index of the input. In other words, given input `n` , return the value at index `n` of the Fibonacci sequence. The Fibonacci sequence 
is a sequence in which each number is the sum of the two preceding ones. Starting from 0 and 1, the first values of the sequence are:
`0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144`.

For example, if our input value equals `n = 6`, the function needs to return 8, which is the value that resides at index 6.

### Conditions and assumptions
- _No function selector_ implies that we need to use the fallback function of the contract, which will save us 4 bytes in runtime bytecode. The fallback function does not take any parameters, so as the problem statement states, the `uint265` input number `n` is passed as 32 bytes length calldata.
- It is assumed that with _runtime bytecode_ only the actual bytecode for the to be developed function is meant. This is because an emtpy contract, e.g.
```
pragma solidity ^0.8.17;

contract Fibonacci{}
```
already translates to creation bytecode
```
6080604052348015600f57600080fd5b50603f80601d6000396000f3fe # initial bytecode 
6080604052600080fdfea2646970667358fe1220fe30fefefefefefe6ea36edb # deployed bytecode
c3e055bd36bc0d8a58083a1dfefe3b6c9898acd664736f6c63430008110033
```
which contains both the initial code to deploy the contract (the first line) as well as the deployed bytecode, separated by opcode `0xfe`. In this case the deployed code already has a length of 63 bytes.

## Solutions

### 1. Naive recursion

The first naive approach is using recursion. On [Github](https://github.com/drujensen/fib) (and related discussion on [Hackernews](https://news.ycombinator.com/item?id=18091655)) an interesting benchmark was done between all major programming languages - except Solidity. Mentioned language are all non-EVM based and thus do not have to deal with gas, only the time and space complexity matters. Hypothetically, for Solidity the naive recursion (including function selector) would look something in the lines of
```
contract Fibonacci {

    function f(uint256 n) public returns(uint256 result) 
    {
        if (n <= 1) return 1;
        else return Fibonacci.f(number - 1) + Fibonacci.f(number - 2);
    }
}
```
Although this produces valid results for `n < 10` with a runtime bytecode of ~ 550 bytes, this approach is a no-go for Solidity. Recursion is computationally expensive, with a time complexity of X. Implementing a recursive approach for Solidity implies that for each recursive function call the PC is reset `n - 1` times to the opcode referring to the start of the function, which would thus result in a potentially infinite amount of gas. In Remix this is observed too, for `n > 20` it starts to hang and gas is very high. Recursion is therefore not a valid solution.

### 2. Memoization

Implementing [memoization](https://nl.wikipedia.org/wiki/Memoization) we can reduce the time complexity from `O(x^n)` to linear time (`O(n)`).   



## References

- Recursive Fibonacci Benchmark using top languages on [Github](https://github.com/drujensen/fib) and [Hackernews](https://news.ycombinator.com/item?id=18091655)
- Medium article: [Fibonacci in Solidity](https://medium.com/coinmonks/fibonacci-in-solidity-8477d907e22a)
- [Hackernews]
