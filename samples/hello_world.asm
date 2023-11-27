.entry main
;.data
;string: .ascii "Hello World!"
;len: .length string
.text
main:
  loadimm  %0  1
  loadimm  %1  1
  add      %0  %1  %0
  loadimm  %1  48        ;; Offset of 48 to get to a char
  add      %0  %1  %0
  storeu32 %1  %0

  loadimm  %0  1  ;; set register 0 to t for syscall stdout write
  loadimm  %1  0  ;; set register 1 to location in memeory
  loadimm  %2  1  ;; set register 1 to location in memeory
  syscall
  loadimm  %0  0  ;; set register 0 to 0 for syscall exit
  loadimm  %1  0  ;; set register 1 to 0 for exit code
  syscall
