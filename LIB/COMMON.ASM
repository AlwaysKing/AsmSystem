; ================================================================
; 通用功能的相关宏定义,使用NASM的16位汇编完成
; 完成功能：
;     intseg, multipush, multipop, callpush, callbackpop, smallcall
;     myseg, memset, memset_unsafe
; ================================================================

%ifndef lib_common
%define lib_common

; ---------------------------------------
; 宏说明：
;   初始化段寄存器
; 使用方法：
;   intseg  DS,ES
; ---------------------------------------
%macro intseg 2
    push ax
    mov ax, %1           
    mov ds, ax   
    mov ax, %2           
    mov es, ax
    pop ax
%endmacro 

; ---------------------------------------
; 宏说明：
;   将指定的一些列寄存器压栈
; 使用方法：
;   multipush    ax,bx,cs,ds,.....
; ---------------------------------------
%macro  multipush 1-*.nolist
%rep  %0                
    push    %1          
    %rotate 1          
%endrep              
%endmacro 

; ---------------------------------------
; 宏说明：
;   将指定的一些列寄存器出栈
; 使用方法：
;   multipop    ax,bx,cs,ds,.....
; 其它说明：
;   寄存器顺序与使用 multipush 的时候需保持一致
; ---------------------------------------
%macro  multipop 1-*.nolist
%rep %0          
    %rotate -1               
    pop     %1          
%endrep               
%endmacro 

; ---------------------------------------
; 宏说明：
;   简化调用时候的传参，此宏定义必须 与 callbackpop 搭配使用
; 使用方法：
;   call    参数1, 参数2，...
; ---------------------------------------
%macro  callpush 1-*;.nolist
%push   callcontext
%assign %$localsize %0
push 0
%rep %0          
    %rotate -1
    push    %1          
%endrep       
%endmacro 

; ---------------------------------------
; 宏说明：
;   简化调用时候的传参，此宏定义必须 与 callpush 搭配使用
; 使用方法：
;   call    返回值
; ---------------------------------------
%macro  callbackpop 1
mov %1, ax
%rep %$localsize          
    pop ax
%endrep
mov ax,%1
pop %1
%pop
%endmacro 

; ---------------------------------------
; 宏说明：
;   封装了 callpush 和  callbackpop 的调用，之后再也不用管参数的压栈顺序了
; 使用方法：
;   call    要调用的函数, 返回值存储地址，{参数1, 参数2, 参数3}
; ---------------------------------------
%macro smallcall 3
callpush %3
call %1
callbackpop %2
%endmacro

; ---------------------------------------
; 宏说明：
;   将指定的段的段地址保存到指定寄存器中
; 使用方法：
;    myseg    段寄存器, 段名称
; ---------------------------------------
%macro  myseg 2.nolist         
    multipush   ax
    ;
    mov ax, section.%2.start
    mov %1,ax
    ;
    multipop    ax             
%endmacro 


; ---------------------------------------
; 宏说明：
;   将指定值复制到指定内存中, 安全函数，不会改变借用的寄存器的值
; 使用方法：
;    memset    借用的寄存器, 内存地址, 值
; ---------------------------------------
%macro  memset 3.nolist         
    multipush   %1
    ;
    mov %1, %3
    mov %2, %1
    ;
    multipop    %1             
%endmacro 

; ---------------------------------------
; 宏说明：
;   将指定值复制到指定内存中, 与memset的不同是，不安全函数，会改变借用的寄存器的值
; 使用方法：
;    memset_byax    借用的寄存器, 内存地址, 值
; ---------------------------------------
%macro  memset_unsafe 3.nolist         
    ;
    mov %1, %3
    mov %2, %1
    ;          
%endmacro 

%endif