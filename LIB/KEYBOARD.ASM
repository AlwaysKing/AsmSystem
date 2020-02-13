; ================================================================
; 键盘相关功能的宏定义,使用NASM的16位汇编完成
; 完成功能：
;     getchar, getline, getpassword
; ================================================================

%ifndef lib_keyboard
%define lib_keyboard
%include "PRINT.ASM"
%include "COMMON.ASM"

; ================================================================
; 调用宏定义
; 所有函数都使用对应的宏定义来调用
; ================================================================
; ---------------------------------------
; 宏说明：
;   获取一个字符输入
; 使用方法：
;    getchar    返回值
; ---------------------------------------
%macro  getchar 1.nolist       
    ;
    call proc_keyboard_clear
    smallcall proc_keyboard_getchar, %1, {0xffff}
    ;             
%endmacro 

; ---------------------------------------
; 宏说明：
;   获取一串字符串
; 使用方法：
;    getno    内存地址, 内存长度, 返回值
; ---------------------------------------
%macro  getline 3.nolist       
    ;
    call proc_keyboard_clear
    smallcall proc_get_line, %3, {0xffff, %1, %2}
    ;             
%endmacro 

; ---------------------------------------
; 宏说明：
;   获取一串密码
; 使用方法：
;    getno    内存地址, 内存长度, 返回值
; ---------------------------------------
%macro  getpassword 3.nolist       
    ;
    call proc_keyboard_clear
    smallcall proc_get_line, %3, {0x0042, %1, %2}
    ;             
%endmacro 

; ================================================================
; 调用函数
; 实际完成功能的函数，尽量不要直接使用函数，而是使用对应的宏定义
; ================================================================
section lib_keyboard_section
; ---------------------------------------
; 函数说明：
;   清理键盘缓存
; 使用方法：
;    call proc_keyboard_clear
; ---------------------------------------
proc_keyboard_clear:
    ; 函数的一些相关定义
    %push keyboard_context         ; 上下文压栈            
    %stacksize large              ; 设置使用bp寄存器来寻址        

    ; 函数体正式开始
    enter       0, 0 ; 确保堆栈平衡，以及开辟空间   
    multipush   ax,         ; 保存原始寄存器值 

.again:
    mov ax,0
    mov ah, 1
    int 16h
    jz .end
    mov ah, 0
    int 16h
    jmp .again
.end:
    multipop   ax               ; 恢复原始寄存器值
    leave                       ; 恢复堆栈

    ret
    %pop                        ; 上下文出栈

; ---------------------------------------
; 函数说明：
;   清理键盘缓存
; 使用方法：
;    使用 getchar, getline, getpassword, getno宏
; ---------------------------------------
proc_keyboard_getchar:
    ; 函数的一些相关定义
    %push keyboard_context         ; 上下文压栈            
    %stacksize large              ; 设置使用bp寄存器来寻址        
    %arg mask:word, rv:word    

    ; 函数体正式开始
    enter       0, 0            ; 确保堆栈平衡，以及开辟空间   
    multipush   ax, bx          ; 保存原始寄存器值 

    ; 获取字符
    mov ax, 0
    int 16h
    mov [rv], ax

    ; 判断显示字符
    mov bx, [mask]
    cmp bx,0
    jz .end
    cmp bx, 0xffff
    jz .printself
    jmp .printmask

.printself:
    mov bx,0
    mov bl, al
    mov [mask], bx
    mov bx, bp  ; 定位mask变量的位置
    add bx, 4
    printf bx, 1

    jmp .end

.printmask:
    mov bx, bp  ; 定位mask变量的位置
    add bx, 4   
    printf bx, 1

    jmp .end
.end:
    multipop   ax, bx            ; 恢复原始寄存器值
    leave                        ; 恢复堆栈

    ret
    %pop                        ; 上下文出栈

; ---------------------------------------
; 函数说明：
;   获取一个字符
; 使用方法：
;    使用  getline, getpassword 宏
; ---------------------------------------
proc_get_line:
    ; 函数的一些相关定义
    %push keyboard_context         ; 上下文压栈            
    %stacksize large              ; 设置使用bp寄存器来寻址        
    %arg mask:word, memaddr:word, memlen:word, rv:word  

    ; 函数体正式开始
    enter       0, 0            ; 确保堆栈平衡，以及开辟空间   
    multipush   ax, bx, cx, si          ; 保存原始寄存器值 

    mov ax, 0
    mov [rv], ax
    mov cx, [memlen]
    mov si, [memaddr]
    mov bx, [mask]

.again:

    ; 获取一个字符
    smallcall proc_keyboard_getchar, ax, {bx}
    cmp al, 0x0d                ; 回车则结束
    jz .end

    ; 将获取到的内容拷贝至内存中
    mov [si], al
    add si, 1

    ; 增长rv的值
    mov ax, [rv]
    add ax, 1
    mov [rv], ax

    loop .again     ; 继续

.end:
    multipop   ax, bx, cx, si    ; 恢复原始寄存器值
    leave                        ; 恢复堆栈

    ret
    %pop                        ; 上下文出栈

%endif