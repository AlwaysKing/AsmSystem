; ================================================================
; 这是运行在裸机上的MBR代码，NASM的16位汇编完成
; 内存加载地址：07c00h 
; 完成功能：
;     加载 2号扇区开始的20个扇区的代码至指定内存地址，并将运行权利转交
; ================================================================

%include "COMMON.ASM"
%include "DISK.ASM"

org 07c00h                     ; 指示编译器 程序加载的位置

projramloadadd equ 07f00h

section .data
     ; 出错字符
     strfailed: db  "Boot Error"
     strfailedlen equ $-strfailed

section .text
     intseg 0, 0
     ; 读取磁盘
     disk_io   2, 14h, projramloadadd, 42h, ax
     ; 判断大小
     cmp ax, 0
     jne error
     jmp projramloadadd

error:
     mov cx, strfailedlen               ; CX = 串长度
     mov bx, 000fh                      ; 页号为0(BH = 0) 黑底白字(BL = 0Fh,高亮)
     mov dx, 0                          ; 列
     mov ax, strfailed
     push bp
     mov bp, ax                         ; ES:BP = 串地址
     mov ax, 01301h                     ; AH = 13, AL = 01h
     int 10h ; 10h 号中断
     pop bp
     jmp $ ; 无限循环

