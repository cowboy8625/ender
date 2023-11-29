.entry main
;.data
;string: .ascii "Hello World!"
;len: .length string
.text
main:
    loadimm     %1    0    ;; ensure that register 1 is empty
    loadimm     %0    72   ;; input 'H' or 0x48 or 72 in register 0
    storeu8     %1    %0   ;; put 'H' on heap
    inc         %1         ;; increment register 1

    loadimm     %0    101  ;; input 'e' or 0x65 or 101 in register 0
    storeu8     %1    %0   ;; put 'e' on heap
    inc         %1         ;; increment register 1

    loadimm     %0    108  ;; input 'l' or 0x6c or 108 in register 0
    storeu8     %1    %0   ;; put 'l' on heap
    inc         %1         ;; increment register 1
    storeu8     %1    %0   ;; put 'l' on heap
    inc         %1         ;; increment register 1

    loadimm     %0    111  ;; input 'o' or 0x6f or 111 in register 0
    storeu8     %1    %0   ;; put 'o' on heap
    inc         %1         ;; increment register 1

    loadimm     %0    32   ;; input ' ' or 0x20 or 32 in register 0
    storeu8     %1    %0   ;; put ' ' on heap
    inc         %1         ;; increment register 1

    loadimm     %0    87     ;; input 'W' or 0x57 or 87 in register 0
    storeu8     %1    %0   ;; put 'W' on heap
    inc         %1         ;; increment register 1

    loadimm     %0    111  ;; input 'o' or 0x6f or 111 in register 0
    storeu8     %1    %0   ;; put 'o' on heap
    inc         %1         ;; increment register 1

    loadimm     %0    114  ;; input 'r' or 0x72 or 114 in register 0
    storeu8     %1    %0   ;; put 'r' on heap
    inc         %1         ;; increment register 1

    loadimm     %0    108  ;; input 'l' or 0x6c or 108 in register 0
    storeu8     %1    %0   ;; put 'l' on heap
    inc         %1         ;; increment register 1

    loadimm     %0    100  ;; input 'd' or 0x64 or 100 in register 0
    storeu8     %1    %0   ;; put 'd' on heap
    inc         %1         ;; increment register 1

    loadimm     %0    33   ;; input '!' or 0x21 or 33 in register 0
    storeu8     %1    %0   ;; put 'd' on heap
    inc         %1         ;; increment register 1

    loadimm     %0    10   ;; input '\n' or 0x0A or 10 in register 0
    storeu8     %1    %0   ;; put '\n' on heap
    inc         %1         ;; increment register 1

    loadimm     %0    1    ;; load register 0 with 1 for a write syscall
    loadimm     %1    0    ;; load register 1 with the string location
    loadimm     %2    13   ;; load 13 into register 2 aka the length of the string
    syscall                ;; syscall
    loadimm     %0    0    ;; load register 0 with 0 for a write syscall
    loadimm     %1    10   ;; load register 0 with 10 for the exit code
    syscall                ;; syscall
