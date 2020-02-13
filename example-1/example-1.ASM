; ================================================================
; 这是运行在裸机上的example-1代码，NASM的16位汇编完成
; 内存加载地址：0A800h 
; 完成功能：
;     将自身移动到1A800H的内存地址之后继续运行，接受一个任意字符输入后结束程序，返回菜单
; ================================================================
%include "COMMON.ASM"
%include "PRINT.ASM"
%include "STRING.ASM"
%include "DISK.ASM"
%include "KEYBOARD.ASM"
%include "MEMORY.ASM"

org 0xA800                     ; 指示编译器 程序加载的位置

section .data
     ; 欢迎字符
     defstring strhello, strhellolen, "im example-1"
     defstring strmove, strmovelen, "im move to 0x1A800"
     defstring strexit, strexitlen, "input anykey to exit"
     pend equ $


section .text
start:
     intseg 0, 0
     printfclear
     printf    strhello, strhellolen 

     ; 修改段地址
     mov ax, 0x1000
     mov es, ax
     mov ax, pend - start + 100h    ; 加100H 的Udine是将变量也一并复制过来，这是偷懒的做法
     memcpy 0xA800, 0xA800, ax, ax
     ; 将自己移动到 0x1A800 的位置继续运行
     mov ax, 0x1000
     mov ds, ax
     mov es, ax
     jmp 0x1000: ( 0xa800 + a800 - start )

a800:
     

     printfendl
     printf strmove, strmovelen

     printfendl
     printf strexit, strexitlen
     getchar ax
     int 88h

     hlt
     jmp $ ; 无限循环

