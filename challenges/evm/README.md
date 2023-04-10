# EVM Challenge

This doc contains the approach for solving the EVM challenge.

## Problem statement 

What is the shortest runtime bytecode you can write for a contract that satisfies:
- Accept calldata of length 32 bytes representing one uint256 (no function selector);
- Returns, as one uint256, the Fibonacci number at the index of the input (the sequence can start at either 0 or 1).

The problem states: the Fibonacci number at the index of the input. In other words, given input `n` , return the value at index `n` of the Fibonacci sequence. The Fibonacci sequence 
is a sequence in which each number is the sum of the two preceding ones. Starting from 0 and 1, the first values of the sequence are:  
`0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144`.

For example, if our input value equals `n = 6`, the function needs to return 8, which is the value that resides at index 6.

## Approach
_No function selector_ implies that we need to use the fallback function of the contract, which will save us 4 bytes in runtime bytecode. The fallback function does not take any parameters, so as the problem statement states, the `uint265` input number `n` is passed as 32 bytes length calldata. In the case of no function selector and `n = 20`, calldata would thus be
`0x00000000000000000000000000000000000000000000000000000000000014`, which is 20 in hexadecimal format padded to 32 bytes. 

Given that **there exist valid solutions of length less than 50 bytes**, Solidity is obviously not the way to go. Compiling a simple empty contract, e.g. 
```
solc --bin-runtime Empty.sol
```
already shows a byte length of few hundreds bytes. On [Github](https://github.com/drujensen/fib) (and related discussion on [Hackernews](https://news.ycombinator.com/item?id=18091655)) an interesting benchmark was done between all major programming languages to compute the Fibonacci number, but mainly in a recursvie manner. Mentioned language are all non-EVM based and thus do not have to deal with gas, only the time- and space-complexity matters. Now recursion has a time complexity of $O(x^n)$, which means that the transaction possibly
consume an infinite amount of gas. A more suffisticated approach is memoization, which only requires one for-loop, thereby reducing the time complexity to $O(n)$, a significant improvement. An example can be found in `Memoization.sol` (not using the fallback functiOn), but this contract too will compile to hundreds of bytes. It does help though, in providing insights in the way to move forward. In pseudocode the memoic approach of returning the `n`-th index of the Fibonacci sequence would boild down to something in the lines of
```
contract Fibonacci {

    fallback() payable external returns (bytes memory b) {

        if n is 0 or 1:
            b = n
        else:
            initalize a = 0 and b = 1
            for i = 2, i <= n, i++:
                c = a + b
                a = b
                b = c
       return b
    }
```

This provides us insights in how we can construct the required components for the workflow.

**Opcode workflow:**
1. Load calldata `n` to the stack
2. If `n` is 0 or 1, jump to return anchor (8)
3. Prepare for-loop by initializing variables
4. Anchor point for start of loop
5. Condition if we should do the loop body
6. Loop body (including incrementing `i`)
7. Jump to start-of-loop anchor (4)
8. Return block


## Opcode blocks

Taking the opcodes workflow as described above, and constructing them separately. Note `stack[1]` is the top item of the stack.

### Load calldata to the top of stack
```
PUSH1 0x00
CALLDATALOAD
```
First push 0 as calldataload offset to the top of the stack, then load calldata to the top of the stack 
Loading calldata of size 32 bytes to the top of the stack. First push 0 as offset for the calldataload to the stack, then load calldata. 

### Return block
Return block to return a value that is on top of the stack at the beginning of this block.
```
JUMPDEST    // return block anchor
PUSH1 0x00
MSTORE
PUSH1 0x20
PUSH1 0x00
RETURN
```
Push 0 to the stack, then store value `stack[2]` in memory with offset 0. This means the first 32 bytes of the memory equal the value that needs to be returned. Finally we push 0x20 (32 decimal) to the stack, then offset 0, such that the first 32 bytes from memory with offset 0 are returned.

### Condition to check calldata equals 0 or 1
```
PUSH1 	0x02  // after this stack = [2][n]
SGT
PUSH1 	0x0c  // jumpdestination in byte offset of JUMPDEST at the top of final return block
JUMPI
```
At the start of this block we have the input data on top (`stack[1]`) of the stack. Then we want to check if the input data is 0 or 1, i.e. smaller than 2. So we push 2 on top of the stack, then check if 2 is greater than the input. If this is the case, we end up with 0 on top of the stack. Next we add the byte offset of the jump destination (depending on total bytesize) of the final return block to the top of the stack, and JUMPI will alter the program counter, on the condition that the calldata is smaller than 2.

### Prepare / initialize for-loop
```
PUSH1  0x00     // a
PUSH1  0x01     // b
PUSH1  0x02     // i, starting index of for-loop. Stack is now [2][1][0][n]
DUP4            // duplicate n to the top of the stack in order to enter the loop condition
```

### Loop condition
Anchor for start of the for-loop including condition to check whether the loop body needs to be executed
```
JUMPDEST  // for-loop anchor. At this point the top two items of the stack are i and n.
EQ
PUSH1   0x0c     // jumpdestination in byte offset containing the anchor for the loop body
JUMPI
```

### Loop body: add last two Fibonacci numbers
_work in progress_

## Runtime bytecode

Overview of overall runtime bytecode in Opcode representation

|    | **Opcode block**               | **Opcode**   | **Value** | **Function**                                                         | Notes                            |   |
|----|--------------------------------|--------------|-----------|----------------------------------------------------------------------|----------------------------------|---|
| 1  | Load calldata                  | PUSH1        | 0x00      | Offset for calldataload                                              |                                  |   |
| 2  |                                | CALLDATALOAD |           | Load calldata to stack with offset 0                                 |                                  |   |
| 3  | Case n equals 0 or 1           | PUSH1        | 0x02      | Value to check if input smaller than 2                               |                                  |   |
| 4  |                                | SGT          |           | Sign-greater-than                                                    |                                  |   |
| 5  |                                | PUSH1        | 0x08      | Byte offset of return block anchor                                   | Byte offset value not checked    |   |
| 6  |                                | JUMPI        |           | Conditionally jump to return block                                   |                                  |   |
| 7  | _Prepare / initalize for loop_ | PUSH1        | 0x00      | Add `a` to stack                                                     |                                  |   |
| 8  |                                | PUSH1        | 0x01      | Add `b` to stack                                                     |                                  |   |
| 9  |                                | PUSH1        | 0x02      | Add `i`, the starting index for the for-loop                         |                                  |   |
| 10 |                                | DUP4         |           | Duplicate the call data from `stack[4]` to the top of the stack      |                                  |   |
| 11 | Loop condition                 | JUMPDEST     |           | Anchor loop condition                                                |                                  |   |
| 12 |                                | EQ           |           | Condition to check if we should execute loop body                    |                                  |   |
| 13 |                                | PUSH1        | 0x        | Jumpdestination byte offset that equals anchor of loop body (15)     | Byte offset value not checked    |   |
| 14 |                                | JUMPI        |           | Conditionally jump to loop body anchor                               |                                  |   |
| 15 | Loop body                      | JUMPDEST     |           | Anchor for loop body                                                 |                                  |   |
| 16 |                                | ADD          |           | Add a and b (see pseudocode)                                         |                                  |   |
| 17 |                                | SWAPX        |           | Swap a with b such that a = b (see pseudocode)                       | Stack index not checked for swap |   |
| 18 |                                | SWAPX        |           | Swap b with c such that b = c (see pseudocode)                       | Stack index not checked for swap |   |
| 19 |                                | DUPX         |           | Get n to top of stack                                                | Stack index not checked          |   |
| 20 |                                | PUSH1        | 0x01      | Value to increment i                                                 |                                  |   |
| 21 |                                | ADD          |           | Increment i                                                          |                                  |   |
| 22 |                                | PUSH1        | 0x        | Add byte offset for loop condition to stack (i.e. byte offest of 11) | Byte offset value not checked    |   |
| 23 |                                | JUMP         |           | Jump to loop condition (11)                                          |                                  |   |
| 24 | Return block                   | JUMPDEST     |           | Anchor for return block                                              |                                  |   |
| 25 |                                | PUSH1        | 0x00      | MSTORE offset                                                        |                                  |   |
| 26 |                                | MSTORE       |           | Store the to be returned value (currently on `stack[1]`) in memory   |                                  |   |
| 27 |                                | PUSH01       | 0x20      | Size of return value (32 bytes)                                      |                                  |   |
| 28 |                                | PUSH1        | 0x00      | Memory offset of return value                                        |                                  |   |
| 29 |                                | RETURN       |           |                                                                      |                                  |   |
