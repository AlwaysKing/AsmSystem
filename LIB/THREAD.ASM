; ================================================================
; 线程相关操作,使用NASM的16位汇编完成
; 完成功能：
;     sleep
; ================================================================

%ifndef lib_thread
%define lib_thread

; ================================================================
; 调用宏定义
; 所有函数都使用对应的宏定义来调用
; ================================================================

; ---------------------------------------
; 宏说明：
;   线程sleep函数, 有个缺陷, 开机正好24小时的时候如果在sleep会出问题
; 使用方法：
;    sleep 秒数, 返回值
; ---------------------------------------
%macro  sleep  2.nolist       
    smallcall proc_sleep, %2, {%1}
%endmacro 

; ================================================================
; 调用函数
; 实际完成功能的函数，尽量不要直接使用函数，而是使用对应的宏定义
; ================================================================
section lib_thread_section
; ---------------------------------------
; 函数说明：
;   内存拷贝
; 使用方法：
;    使用宏定义 memcpy
; ---------------------------------------
proc_sleep:
    ; 函数的一些相关定义
    %push disk_io_context         ; 上下文压栈            
    %stacksize large              ; 设置使用bp寄存器来寻址        
    %arg time:word, rv:word    ; 定义参数

    ; 函数体正式开始
    enter       0,    0   ; 确保堆栈平衡，以及开辟空间   
    multipush   ax,cx,bx,ds            ; 保存原始寄存器值 

    mov ax, [time]
    mov bl, 18
    mul bl
    mov [time], ax
.again:
    ; 初始化
    mov ax, 0
    mov ds, ax
    mov ax, [046ch]
    ; 真sleep 等待中断触发
    hlt
    ; 之后比较事件
    mov bx, [046ch]
    cmp bx,ax
    ; 相等说明时间没过去，继续等待
    je .again

    ja .bthena  ;说明重计数了
        mov cx, 0xffff
        sub cx, ax
        add bx, cx
        jmp .count
.bthena:
    sub bx,ax
.count:
    mov ax, [rv]
    add bx, ax  ;累计过去的时间
    mov [rv], bx
    mov ax, [time]

    cmp ax, bx
    ; 还没到时间
    ja .again
    jmp .wakeup

.wakeup:
    mov ax, [rv]
    mov bl, 18
    div bl
    cmp ah, 9
    jb .noadd
    add al, 1
.noadd:
    mov ah,0
    mov [rv], ax

    multipop   ax,cx,bx,ds               ; 恢复原始寄存器值
    leave                                ; 恢复堆栈

    ret
    %pop                        ; 上下文出栈
%endif