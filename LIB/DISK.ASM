; ================================================================
; 这是关于磁盘操作的相关宏定义,使用NASM的16位汇编完成
; 完成功能：
;     disk_io
; ================================================================
%ifndef lib_disk
%define lib_disk
%include "COMMON.ASM"

; ================================================================
; 调用宏定义
; 所有函数都使用对应的宏定义来调用
; ================================================================

    ; ---------------------------------------
    ; 宏说明：
    ;   封装了对磁盘读写的调用，实际使用的是函数disk_io
    ; 使用方法：
    ;   disk_io  磁盘起始扇区, 扇区数, 内存地址, 读(42h)/写(43h), 返回值
    ;   
    ; ---------------------------------------
%macro  disk_io 5.nolist
    push strict word 0      ; 返回值 
    push strict word %4     ; 读(42h)/写(43h) opertation
    push strict word %3     ; 内存地址 memaddr
    push strict word %2     ; 扇区数 count
    push strict word %1     ; 磁盘起始扇区 offset     
    call proc_disk_io
    mov %5, ax
    pop ax
    pop ax
    pop ax
    pop ax
    mov ax, %5
    pop %5
%endmacro 

; ================================================================
; 调用函数
; 实际完成功能的函数，尽量不要直接使用函数，而是使用对应的宏定义
; ================================================================

; 定义自己的段
section lib_disk_section

struc disk_io_param_context
    .PacketSize  resb    1;  数据包尺寸(16字节)
    .Reserved    resb    1;  ==0
    .BlockCount  resw    1; // 要传输的数据块个数(以扇区为单位)
    .BufferAddr1 resw    1; // 传输缓冲地址 segment
    .BufferAddr2 resw    1; // 传输缓冲地址 offset 
    .BlockNum1  resw     1; // 磁盘起始绝对块地址
    .BlockNum2  resw     1; // 磁盘起始绝对块地址
    .BlockNum3  resw     1; // 磁盘起始绝对块地址
    .BlockNum4  resw     1; // 磁盘起始绝对块地址 
endstruc

    ; ---------------------------------------
    ; 函数说明：
    ;   磁盘读写的封装函数
    ; 使用方法：
    ;   使用宏定义, disk_io 
    ; ---------------------------------------
proc_disk_io:
    ; 函数的一些相关定义
    %push disk_io_context         ; 上下文压栈            
    %stacksize large              ; 设置使用bp寄存器来寻址        
    %assign %$localsize 16 
    %arg offset:word, count:word, memaddr:word, opertation:word, rv:word    ; 定义参数
    %local a1:qword, param:qword

    ; 函数体正式开始
    enter       16,    0   ; 确保堆栈平衡，以及开辟空间   
    multipush   ax,cx,bx,ds,si            ; 保存原始寄存器值 
    
    memset_unsafe al, [param + disk_io_param_context.PacketSize], 16            ; 给PacketSize 赋值16
    memset_unsafe al, [param + disk_io_param_context.Reserved], 0               ; 给Reserved 设置为0
    memset_unsafe ax, [param + disk_io_param_context.BlockCount], [count]       ; 设置去取的扇区数量
    memset_unsafe ax, [param + disk_io_param_context.BufferAddr1], [memaddr]    ; 内存段地址
    memset_unsafe ax, [param + disk_io_param_context.BufferAddr2], 0            ; 内存偏移地址
    memset_unsafe ax, [param + disk_io_param_context.BlockNum1], [offset]       ; 磁盘地址
    memset_unsafe ax, [param + disk_io_param_context.BlockNum2], 0              ; 磁盘地址
    memset_unsafe ax, [param + disk_io_param_context.BlockNum3], 0              ; 磁盘地址
    memset_unsafe ax, [param + disk_io_param_context.BlockNum4], 0             ; 磁盘地址

    ; ds:si是磁盘本参数的地址
    mov ax, 0
    mov ds, ax
    mov ax, bp
    sub ax, 16
    mov si, ax
    mov ah, [opertation]
    mov dl, 80h
    int 13h
    mov al,ah
    mov ah,0
    mov [rv], ax

    multipop   ax,cx,bx,ds,si               ; 恢复原始寄存器值
    leave                                   ; 恢复堆栈

    ret
    %pop                        ; 上下文出栈







%endif

