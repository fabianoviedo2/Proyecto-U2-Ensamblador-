INCLUDE Irvine32.inc

.data
mensaje BYTE "Escribre tu nombre: ", 0

.code
main PROC
  mov edx, OFFSET mensaje
   call writeString
   exit
main ENDP 

END main 