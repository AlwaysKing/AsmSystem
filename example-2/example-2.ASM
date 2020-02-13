; ================================================================
; 这是运行在裸机上的example-2代码，NASM的16位汇编完成
; 内存加载地址：0A800h 
; 完成功能：
;     循环5次每次睡眠1S
; ================================================================
%include "COMMON.ASM"
%include "PRINT.ASM"
%include "STRING.ASM"
%include "THREAD.ASM"
%include "KEYBOARD.ASM"


org 0xA800                     ; 指示编译器 程序加载的位置

section .data
     ; 欢迎字符
     defstring strSleep, strSleepLen, "sleep"
     defstring strWakeUp, strWakeUplen, "wake up"
     defstring strTip, strTipLen,"wait for 5S"
section .text
start:
     intseg 0, 0
     printf_init
     printfclear
     printf    strSleep, strSleepLen 
     mov cx, 5
waittip:

     printfendl
     printf    strTip, strTipLen 
     ; 等待1s
     sleep 1, ax
     mov bx, strTip+9
     mov ax, [bx]
     sub ax, 1
     mov [bx], ax
     loop waittip

     printfendl
     printf strWakeUp, strWakeUplen


     ; 结束
     getchar ax
     int 88h

     jmp $ ; 无限循环

