; ================================================================
; 这是关于打印信息的相关宏定义,使用NASM的16位汇编完成
; 完成功能：
;     printf_init, printfclear, printfreturn, printfenter, printfendl
;     printfaddlen, printf, printf_color
; ================================================================

%ifndef lib_print
%define lib_print

%include "COMMON.ASM"

; ================================================================
; 调用宏定义
; 所有函数都使用对应的宏定义来调用
; ================================================================
%macro printf_init 0
    call proc_printf_init
%endmacro


; ---------------------------------------
; 宏说明：
;   清楚屏幕内容
; 使用方法：
;   printfreturn    
; ---------------------------------------
%macro printfclear 0
    call proc_printf_clear
%endmacro

; ---------------------------------------
; 宏说明：
;   回到行的开头
; 使用方法：
;   printfreturn    
; ---------------------------------------
%macro printfreturn 0
    call proc_printfreturn
%endmacro

; ---------------------------------------
; 宏说明：
;   换到下一行
; 使用方法：
;   printfaddlen    长度
; ---------------------------------------
%macro printfenter 0
    call proc_printfenter
%endmacro


; ---------------------------------------
; 宏说明：
;   回车换行
; 使用方法：
;   printfendl    长度
; ---------------------------------------
%macro printfendl 0
    call proc_printfendl
%endmacro


; ---------------------------------------
; 宏说明：
;   增加每一行的打印起始点坐标
; 使用方法：
;   printfaddlen    长度
; ---------------------------------------
%macro printfaddlen 1
    multipush ax
    push %1
    call proc_printfaddlen
    pop ax
    multipop ax
%endmacro

; ---------------------------------------
; 宏说明：
;   打印一段字符串
; 使用方法：
;   printf    字符串起始地址,字符串的长度
; ---------------------------------------
%macro printf 2
    multipush ax
    push %2
    push %1
    call proc_printf
    pop ax
    pop ax
    multipop ax
%endmacro

; ---------------------------------------
; 宏说明：
;   打印一段字符串
; 使用方法：
;   printf    字符串起始地址,字符串的长度, 颜色
; 其他说明：
;       颜色
;        0	黑色		8	灰色	
;        1	蓝色		9	亮蓝色	 
;        2	绿色		A	亮绿色	
;        3	青色		B	亮青色	
;        4	红色		C	亮红色	
;        5	紫红色		D	亮紫红色	
;        6	棕色		E	黄色	
;        7	银色	 	F	白色	
; ---------------------------------------
%macro printf_color 3
    multipush ax
    push %3
    push %2
    push %1
    call proc_printf_color
    pop ax
    pop ax
    pop ax
    multipop ax
%endmacro


; ================================================================
; 调用函数
; 实际完成功能的函数，尽量不要直接使用函数，而是使用对应的宏定义
; ================================================================

section .bss
    lib_string_hang resb 1              ; 最多25行
    lib_string_lie  resb 1              ; 一行最多80个字符
section lib_print_section

; ---------------------------------------
; 函数说明：
;   初始化打印信息，主要是初始化行列的初始值，和屏幕模式
; 使用方法：
;   printfaddlen    长度
; ---------------------------------------
proc_printf_init:
    enter 0, 0
    multipush   ax
    mov ax, 0
    mov [lib_string_hang], al
    mov [lib_string_lie], al
    multipop   ax
    leave
    ret

; ---------------------------------------
; 函数说明：
;   重新设定光标位置
; 使用方法：
;   printfaddlen    长度
; ---------------------------------------
proc_printf_pos:
    enter 0, 0
    multipush ax,bx,dx
    mov ax,0
    mov ah, 02h
    mov bh,0
    mov dh, [lib_string_hang]
    mov dl, [lib_string_lie]
    int 10h
    multipop ax,bx,dx
    leave
    ret

; ---------------------------------------
; 函数说明：
;   回到行的开头
; 使用方法：
;   printfreturn    
; ---------------------------------------
proc_printfreturn:
    enter 0, 0
    multipush   ax
    mov al, 0 
    mov [lib_string_lie],  al
    call proc_printf_pos
    multipop   ax   
    leave
    ret
; ---------------------------------------
; 函数说明：
;   换到下一行
; 使用方法：
;   printfaddlen    长度
; ---------------------------------------
proc_printfenter:
    enter 0, 0
    multipush   ax
    mov al, [lib_string_hang] 
    cmp al, 24                         ; 如果 lib_string_hang = 24，那么不能再增加了
    jz  .donothing
    add al, 1                          ; 否则 AL+1
    mov [lib_string_hang],  al
    call proc_printf_pos
.donothing:
    multipop   ax   
    leave
    ret

; ---------------------------------------
; 函数说明：
;   回车换行
; 使用方法：
;   printfendl    长度
; ---------------------------------------
proc_printfendl:
    enter 0, 0
    printfenter
    printfreturn
    leave
    ret

; ---------------------------------------
; 函数说明：
;   增加每一行的打印起始点坐标
; 使用方法：
;   printfaddlen    长度
; ---------------------------------------
proc_printfaddlen:
    %push disk_io_context         ; 上下文压栈            
    %stacksize large              ; 设置使用bp寄存器来寻址        
    %arg length:word ; 定义参数

    enter 0, 0
    multipush   ax
    mov ax, 0
    mov al,[lib_string_lie]
    add ax, [length]
.again:
    cmp ax, 80
    ja .dayu
    jb .xiaoyu
    jmp .dengyu
.xiaoyu:   ; 小于就结束了
    mov [lib_string_lie], al 
    jmp .end           
.dayu:     ; 大于，还需要循环
    sub ax, 80
    printfendl
    jmp .again
.dengyu:   ; 等于也结束了
    printfendl
.end:
    multipop   ax
    leave
    ret

    %pop

; ---------------------------------------
; 函数说明：
;   初始化打印信息，主要是初始化行列的初始值，和屏幕模式
; 使用方法：
;   printfaddlen    长度
; ---------------------------------------
proc_printf_clear:
    enter 0, 0
    multipush   ax,cx,dx,bx

    mov ah,0x06
    mov al,0   ;清窗口
    mov cx,0   ;左上角的行号
    mov dh,25  ;右下角的行号
    mov dl,80  ;右下角的行号
    mov bh,0x0f;属性为黑底白字
    int 0x10

    mov al, 0 
    mov [lib_string_lie],  al
    mov [lib_string_hang],  al
    call proc_printf_pos

    multipop   ax,cx,dx,bx
    leave
    ret

; ---------------------------------------
; 函数说明：
;   打印一段字符串
; 使用方法：
;   printf    字符串起始地址,字符串的长度
; ---------------------------------------
proc_printf:
    %push disk_io_context         ; 上下文压栈            
    %stacksize large              ; 设置使用bp寄存器来寻址        
    %arg offset:word, length:word ; 定义参数

    enter 0, 0
    multipush   ax,bx,cx,dx,bp      ; 将这段宏用到的寄存器压栈，保存内容

    mov cx, [length]                ; CX = 串长度
    mov bx, 000fh                   ; 页号为0(BH = 0) 黑底白字(BL = 0Fh,高亮)
    mov dl, [lib_string_lie]        ; 列
    mov dh, [lib_string_hang]       ; 行

    mov ax, [offset]
    push bp
    mov bp, ax                      ; ES:BP = 串地址
    mov ax, 01301h                  ; AH = 13, AL = 01h
    int 10h ; 10h 号中断
    pop bp

    mov cx, [length]
    printfaddlen    cx

    multipop   ax,bx,cx,dx,bp       ; 恢复之前保存的内容
    leave
    ret

    %pop

; ---------------------------------------
; 函数说明：
;   打印一段字符串
; 使用方法：
;   printf    字符串起始地址,字符串的长度, 颜色
; 其他说明：
;       颜色
;        0	黑色		8	灰色	
;        1	蓝色		9	亮蓝色	 
;        2	绿色		A	亮绿色	
;        3	青色		B	亮青色	
;        4	红色		C	亮红色	
;        5	紫红色		D	亮紫红色	
;        6	棕色		E	黄色	
;        7	银色	 	F	白色	
; ---------------------------------------
proc_printf_color:
    %push disk_io_context         ; 上下文压栈            
    %stacksize large              ; 设置使用bp寄存器来寻址        
    %arg offset:word, length:word, color:word       ; 定义参数

    enter 0, 0
    multipush   ax,bx,cx,dx,bp      ; 将这段宏用到的寄存器压栈，保存内容
    mov cx, [length]                ; CX = 串长度

    mov bx, [color]                 ; 前景色和背景色
    mov bh, 0h                      ; 页号为0(BH = 0) 
    mov dl, [lib_string_lie]        ; 列
    mov dh, [lib_string_hang]       ; 行

    mov ax, [offset]
    push bp
    mov bp, ax                      ; ES:BP = 串地址
    mov ax, 01301h                  ; AH = 13, AL = 01h
    int 10h ; 10h 号中断
    pop bp
    
    mov cx, [length]
    printfaddlen    cx

    multipop   ax,bx,cx,dx,bp       ; 恢复之前保存的内容
    leave
    ret

    %pop
%endif