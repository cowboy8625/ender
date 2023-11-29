# VM

This is the Ender VM.

### Opcodes

| Instruction | Mnemonic | Description                                                                                           |
| ----------- | -------- | ----------------------------------------------------------------------------------------------------- |
| 0           | Load     | load %0 %1                                                                                            |
| 1           | LoadImm  | loadImm %0 123                                                                                        |
| 2           | Storeu8  | store %0 %1 ; stores only the first 8 bits of the register                                            |
| 3           | Storeu16 | store %0 %1 ; stores only the first 16 bits of the register                                           |
| 4           | Storeu32 | store %0 %1 ; stores all of the register into the heap                                                |
| 5           | Inc      | inc %0                                                                                                |
| 6           | Push     | push %0                                                                                               |
| 7           | Pop      | pop %0                                                                                                |
| 8           | Add      | add %0 %1 %0 ; add lhs rhs destination                                                                |
| 9           | SysCall  | system ; call (syscall does not take any arguments)                                                   |
|             |          | - Exit program: %0 = 0, %1 = 0                                                                        |
|             |          | - Write to stdout: %0 = 1, %1 = (string location on heap), %2 = length, %3 = (0 for data, 1 for heap) |
|             |          | - Write to stderr: %0 = 1, %1 = (string location on heap), %2 = length                                |

### Registers

| Register | Description     |
| -------- | --------------- |
| %0       | general purpose |
| %1       | general purpose |
| %2       | general purpose |
| %3       | general purpose |
| %4       | general purpose |
| %5       | general purpose |
| %6       | general purpose |
| %7       | general purpose |
| %8       | general purpose |
| %9       | general purpose |
| %10      | general purpose |
| %11      | general purpose |
| %12      | general purpose |
| %13      | general purpose |
| %14      | general purpose |
| %15      | general purpose |
| %16      | general purpose |
| %17      | general purpose |
| %18      | general purpose |
| %19      | general purpose |
| %20      | general purpose |
| %21      | general purpose |
| %22      | general purpose |
| %23      | general purpose |
| %24      | general purpose |
| %25      | general purpose |
| %26      | general purpose |
| %27      | general purpose |
| %28      | general purpose |
| %29      | general purpose |
| %30      | general purpose |
| %31      | general purpose |

- [ ] **Subtraction (`Sub`):** Similar to addition but subtracts the second operand from the first.

- [ ] **Multiplication (`Mul`):** Multiplies two values.

- [ ] **Division (`Div`):** Divides the first operand by the second.

- [ ] **Comparison Instructions (`Cmp`):** Instructions for comparing values (equal, not equal, greater than, less than, etc.). These often set flags in a status register that can be used for conditional jumps.

- [ ] **Conditional Jumps (`Jnz`, `Jz`, `Jg`, `Jl`, etc.):** Jumps to a specified location in the program based on the flags set by a previous comparison.

- [ ] **Bitwise Operations (`And`, `Or`, `Xor`, `Not`):** Perform bitwise operations on binary values.

- [x] **Load Effective Address (`Lea`):** Calculates the effective address of a memory operand and loads it into a register.

- [ ] **Move (`Mov`):** Copies data from one location to another.

- [ ] **Function Call (`Call`):** Jumps to a subroutine or function and stores the return address.

- [ ] **Return from Function (`Ret`):** Returns from a subroutine, popping the return address from the stack.

- [ ] **Shift Instructions (`Shl`, `Shr`):** Perform logical or arithmetic shifts on binary values.

- [ ] **Negation (`Neg`):** Negates a value (changes the sign).

- [x] **Increment (`Inc`)/Decrement (`Dec`):** Increase or decrease the value of a register or memory location.

- [ ] **Stack Manipulation (`Push`, `Pop`):** Pushes a value onto the stack or pops a value from the stack.

- [ ] **Floating-Point Operations (`Fadd`, `Fsub`, `Fmul`, `Fdiv`, etc.):** If your VM supports floating-point operations, you might need instructions for these.

- [ ] **Bitwise Shift Instructions (`Sal`, `Sar`):** Similar to shifts but with arithmetic behavior.

- [x] **Load Immediate (`LoadImm`):** Load an immediate value into a register.

- [ ] **Memory Copy (`Memcpy`):** Copy a block of memory from one location to another.

Remember that the instructions you choose should align with the goals and use cases of your language VM. Additionally, consider the simplicity and efficiency of your instructions for implementation and execution.
