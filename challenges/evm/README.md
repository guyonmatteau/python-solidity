# EVM Challenge

This doc contains the approach for solving the EVM challenge.

## Problem statement 

What is the shortest runtime bytecode you can write for a contract that satisfies:
- Accept calldata of length 32 bytes representing one uint256 (no function selector);
- Returns, as one uint256, the Fibonacci number at the index of the input (the sequence can start at either 0 or 1).

## Approach
The problem states: the Fibonacci number at the index of the input. In other words, given input `n` , return the value at index `n` of the Fibonacci sequence. The Fibonacci sequence 
is a sequence in which each number is the sum of the two preceding ones:

| n    | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7  | 8  | 8  | 9  | 10 | 11  | 12  | 13  | 14  | 15  | 16   | ... | 100                         |
|------|---|---|---|---|---|---|---|----|----|----|----|----|-----|-----|-----|-----|-----|------|-----|-----------------------------|
| F(n) | 0 | 1 | 1 | 2 | 3 | 5 | 8 | 13 | 21 | 34 | 55 | 89 | 144 | 233 | 377 | 610 | 987 | 1597 | ... | 354,224,848,179,261,915,075 |


_No function selector_ implies that we need to use the fallback function of the contract, which will save us 4 bytes in runtime bytecode. The fallback function does not take any parameters, so as the problem statement states, the `uint265` input number `n` is passed as 32 bytes length calldata. In the case of no function selector and `n = 20`, calldata would thus be
`0x00000000000000000000000000000000000000000000000000000000000014`, which is 20 in hexadecimal format padded to 32 bytes. 

Given that **there exist valid solutions of length less than 50 bytes**, Solidity is obviously not the way to go. Compiling a simple empty contract, e.g. 
```
solc --bin-runtime Empty.sol
```
already shows a byte length of few hundreds bytes. On [Github](https://github.com/drujensen/fib) (and related discussion on [Hackernews](https://news.ycombinator.com/item?id=18091655)) an interesting benchmark was done between all major programming languages to compute the Fibonacci number, but mainly in a recursive manner. Mentioned language are all non-EVM based and thus do not have to deal with gas, only the time- and space-complexity matters. Now recursion has a time complexity of $O(x^n)$, which means that the transaction possibly
consume an infinite amount of gas. A more suffisticated approach is memoization, which only requires one for-loop, thereby reducing the time complexity to $O(n)$, a significant improvement. An example can be found in `Memoization.sol` (not using the fallback function), but this contract too will compile to hundreds of bytes. It does help though, in providing insights in the way to move forward. In pseudocode the memoic approach of returning the $n$-th index of the Fibonacci sequence would boild down to something in the lines of
```
contract Fibonacci {

    fallback() payable external returns (bytes memory k) {
        initialize j = 0
        initialize k = 0
        for {i = 2, i <= n, i++}:
            m = k + j
            j = k
            k = m
       return k
    }
```

This provides us insights in how we can construct the required components for the workflow. In order to get to the opcode workflow, first a opcode schema was developed for a simple for-loop with a summed variable (see Appendix A1). From there onwards the Fibonacci logic was added by adding an extra variable and thinking through the loop body.

## Opcode workflow
1. Load calldata $n$ to the stack
2. Initialize variables. 
3. Loop condition: determine if we need to execute the loop body. If $n \in [0, 1]$ jump to return anchor. This is handled by instantiating $i = 2$.
4. Loop body
   1. Increment counter `i`
   2. Execute body: Fibonacci logic
5. Jump back to loop condition
6. Return block


## Opcode blocks

Now the separate opcode blocks can be constructed (independently of their context) as referred to above. Note `stack[1]` is the top item of the stack. Each time it is commented with `stack: [x]` means the stack **after** applying the operation. The separate blocks exclude jump destinations. They are added at the end to the loop condition and the return block. `[0/1]` indicates the result of an evaluation, i.e. `0` or `1`.

### 1. Load calldata to the top of stack
```
PUSH1 0x00      // stack after operation: [0]
CALLDATALOAD    // stack after operation: [n]
```

### 2. Initalize variables for loop
```
PUSH1 0x01      // Instanstiate k = 1: [k]
PUSH1 0x00      // Instanstiate j = 0: [j][k]
```

### 3. Loop condition 
Condition to check if the the loop body needs to be executed, i.e. basically evaluationg whether `i <= n`, or `i > n`. For this the loop variables are duplicated.
Starting with stack `[i][n]` (loop variables), duplicate and check condition:
```
DUP2        // stack:           [n][i][n]
DUP2        // stack:           [i][n][i][n]   
GT          // evaluate i <= n: [0/1][i][n]
PUSH1 0xYY  // add jump destination of return block, if block does not need to be executed: [returnblock][0/1][i][n]
JUMPI
```

### 4. Loop body: increment counter
Incrementing counter `i` is as simple as
```
PUSH1 0x01      // stack: [1]i]
ADD             // stack: [i+1]
```

### 5. Loop body: Fibonacci logic
For Fibonacci, it is relevant that  
$
l = k + j \\
k = j \\
j = l  \\
$ 
can also be written as   
$
k^* = k + j \\ 
k = j  \\
j = k^* = k + j  \\
$
and thus that we only need to update two variables, not three:
```
DUP1    // duplicate k:     [k][k][j]
SWAP2   // swap k and j:    [j][k][k]
ADD     // add j and k:     [k*][k]
```

### 6. Jump to loop condition
```
PUSH1 0xYY  // jump destination of loop condition, to be determined during compilation
JUMP
```

### 7. Return block
Return block to return a value that is on top of the stack at the beginning of this block.
```
JUMPDEST        // return block anchor
PUSH1 0x00      // MSTORE offset: [0][k*][k]
MSTORE
PUSH1 0x20
PUSH1 0x00
RETURN
```
Push 0 to the stack, then store value `stack[2]` in memory with offset 0. This means the first 32 bytes of the memory equal the value that needs to be returned. Finally we push 0x20 (32 decimal) to the stack, then offset 0, such that the first 32 bytes are returned, which is $k^*$.

## Version 1
Combining the above blocks, adding a `JUMPDEST` for the loop condition and the return block, and adding a few swaps and pops we arrive at the first version of our Fibonacci code.

| Opcode block                       | **Name**     | **Value** | **Function**                                 | **Stack after operation**      |
|------------------------------------|--------------|-----------|----------------------------------------------|--------------------------------|
| **Load calldata**            | PUSH1        | 0x00      | Offset to load calldata                      | [0]                            |
|                                    | CALLDATALOAD |           |                                              | [n]                            |
| **Prepare / initalize for loop**   | PUSH1        | 0x01      | Instantiate k = 1                            | [k][n]                         |
|                                    | PUSH1        | 0x00      | Instantiate j = 0                            | [j][k][n]                      |
|                                    | SWAP2        |           |                                              | [n][k][j]                      |
|                                    | PUSH1        | 0x02      | Instantiate i = 2                            | [i][n][k][j]                   |
| **Loop condition [loopcondition]** | JUMPDEST     |           | Check if we need to run the loop body        |                                |
|                                    | DUP2         |           | Duplicate n                                  | [n][i][n][k][j]                |
|                                    | DUP2         |           | Duplicate i                                  | [i][n][i][n][k][j]             |
|                                    | GT           |           | Check if i > n, if true jump to return block | [0/1][i][n][k][j]              |
|                                    | PUSH1        | 0x1c      | Add jump destination of return block         | [returnblock][0/1][i][n][k][j] |
|                                    | JUMPI        |           |                                              |                                |
| **Loop body: increment counter**   | PUSH1        | 0x01      | Add increment for i                          | [1][i][n][k][j]                |
|                                    | ADD          |           | Increment i                                  | [i+1][n][k][j]                 |
| **Loop body: Fibonacci**           | SWAP2        |           | Swap k with i                                | [k][n][i+1][j]                 |
|                                    | DUP1         |           | Duplicate k                                  | [k][k][n][i+1][j]              |
|                                    | SWAP4        |           | Swap k with j                                | [j][k][n][i+1][k]              |
|                                    | ADD          |           | Add k + j = k*                               | [k*][n][i+1][k]                |
|                                    | SWAP2        |           | Swap k* with i                               | [i+1][n][k*][k]                |
| **Jump back to loop condition**    | PUSH1        | 0x0a      | Add jump destination of loop condition       | [loopcondition][i+1][n][k*][k] |
|                                    | JUMP         |           |                                              |                                |
| **Return block [returnblock]**     | JUMPDEST     |           | Jump destination for return block            |                                |
|                                    | POP          |           | Pop i off the stack                          | [n][k*][k]                     |
|                                    | POP          |           | Pop n off the stack                          | [k*][k]                        |
|                                    | PUSH1        | 0x00      | MSTORE offset                                | [0][k*][k]                     |
|                                    | MSTORE       |           | Store to be returned value in memory         |                                |
|                                    | PUSH1        | 0x20      | Return size 32 bytes                         | [20]                           |
|                                    | PUSH1        | 0x00      | Return offset                                | [0][20]                        |
|                                    | RETURN       |           | Return k* to caller                          |                                |

This is a solution valid for the Fibonacci sequence where $n \in [1, 12]$: since we initalize $k = 1$ we get $F(0) = 1$ which is not correct, and since $k, j$ are instantiated as 1 byte values it can only return correctly until $F(12) = 233$; the max value it can return is $16^2 = 256$. The bytecode representation of this solution is `600035600160009160025b818111601c576001019180930191600a565b505060005260206000f3`, which is **39 bytes** long.

## Version 2
Now the Fibonacci sequence until `n = 12` is a start. Let's make that bigger.



## Additional possible solutions


