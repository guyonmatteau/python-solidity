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
_No function selector_ implies that we need to use the fallback function of the contract, which will save us 4 bytes in runtime bytecode. The fallback function does not take any parameters, so as the problem statement states, the `uint265` input number `n` is passed as 32 bytes length calldata. In the case of no function selector and `n = 20`, calldata would thus be
`0x00000000000000000000000000000000000000000000000000000000000014`, which is 20 in hexadecimal format padded to 32 bytes. 

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

## Non-working and working solutions

### 1. Naive recursion

The first naive approach is using recursion. On [Github](https://github.com/drujensen/fib) (and related discussion on [Hackernews](https://news.ycombinator.com/item?id=18091655)) an interesting benchmark was done between all major programming languages - except Solidity. Mentioned language are all non-EVM based and thus do not have to deal with gas, only the time- and space-complexity matters. Hypothetically, for Solidity the naive recursion (including function selector) would look something in the lines of
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

Implementing [memoization](https://nl.wikipedia.org/wiki/Memoization) we can reduce the time complexity from `O(x^n)` to linear time (`O(n)`). Again here we know that Solidity will be way above 50 bytes.


### 3. EVM Opcodes

In order to develop the required logic in Opcodes, the following workflow components would be needed:
- Load calldata (n) of size 32 bytes.
- Determine if n equals zero or one. If the case return n.
- Determine Fibonacci series
- Return result

#### Put CALLDATA on top of stack
Loading calldata of size 32 bytes to the top of the stack. First push 0 as offset for the calldataload to the stack, then load calldata:
```
PUSH1 0x00
CALLDATALOAD
```

#### Return block
Return block to return a value that is on top of the stack:
```
JUMPDEST
PUSH1 0x00
MSTORE
PUSH1 0x20
PUSH1 0x00
RETURN
```
Here we add 0 on top of the stack, such that the value (CALLDATA) on stack index 2 is stored in memory with offset 0. Finally we push 0x20 (32 decimal) to the stack, then offset 0, such that the first 32 bytes from memory with offset 0 are returned.

#### Case CALLDATA 0 or 1
Conditional block to return input data if input data is 0 or 1. 
```
PUSH1 	0x02
SGT
PUSH1 	0x0c  // jumpdestination in byte offset of JUMPDEST at the top of final return block
JUMPI
```
At the start of this block we have the input data on top (stack[1]) of the stack. Then we want to check if the input data is 0 or 1, i.e. smaller than 2. So we push 2 on top of the stack, check if 2 is greater than the input. If this is the case, we end up with 0 on top of the stack. Next we add the byte offset of the jump destination of the final return block to the top of the stack, and JUMPI will alter the program counter, on the condition that the calldata is smaller than 2.

#### Case CALLDATA > 2 - Fibonacci series



## References

- Recursive Fibonacci Benchmark using top languages on [Github](https://github.com/drujensen/fib) and [Hackernews](https://news.ycombinator.com/item?id=18091655)
- Medium article: [Fibonacci in Solidity](https://medium.com/coinmonks/fibonacci-in-solidity-8477d907e22a)
- [Hackernews]
