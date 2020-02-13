; ================================================================
; 这是运行在裸机上的ProgramLoader代码，NASM的16位汇编完成
; 内存加载地址：07f00h 
; 完成功能：
;    1. 提供子程序退出到本程序的INT 88h服务
;    2. 加载位于64扇区的文件索引，显示可启动的程序列表
;    3. 接受用户指令调用子程序
; ================================================================
%include "COMMON.ASM"
%include "PRINT.ASM"
%include "STRING.ASM"
%include "DISK.ASM"
%include "KEYBOARD.ASM"

; ++++++++++++++++++++++++++++++++++++++++
; 全局定义
; ++++++++++++++++++++++++++++++++++++++++
org 07f00h                     ; 指示编译器 程序加载的位置

ProgramLoadAddr equ 0xA800
ProgramItemsize equ 20

; ++++++++++++++++++++++++++++++++++++++++
; 数据结构
; ++++++++++++++++++++++++++++++++++++++++
; menuitem格式
struc ProgramItem
     .fileanme resb 16
     .filesize resb 2
     .fileoffset resb 2
endstruc

; ++++++++++++++++++++++++++++++++++++++++
; 数据段
; ++++++++++++++++++++++++++++++++++++++++
section .data
     ; 欢迎字符
     defstring strWelcome, strWelcomelen, "Welcome To Asm System"
     defstring strLoadFilErr, strLoadFilErrLen, "Load Program List Error"
     defstring strFileInfoErr, strFileInfoErrLen, "Program List Invalid"
     defstring strProgramListSign,  strProgramListSignLen, "ASMFS"
     defstring strProgrmWelcome,  strProgrmWelcomeLen, "Please Select Program To Run (1-9)"
     defstring strInputTip,  strInputTipLen, "Input No: "
     defstring strInputError,  strInputErrorLen, "Input Error"
; ++++++++++++++++++++++++++++++++++++++++
; 变量段
; ++++++++++++++++++++++++++++++++++++++++
section .bss
ProgramListSign:
     resb 6                                 ; 6字节的标识符
ProgramCount:
     resb 2                                 ; 2字节表示程序的数量
perlist:
     resb 2                                 ; 上一个列表缩在扇区， 暂不支持
nextlist:
     resb 2                                 ; 下一个列表缩在的扇区， 暂不支持
ProgramListItem:
     resb 25*ProgramItemsize                 ; 20个文件选项 每个20 字节 20*25 = 500
                                             ; 所以这里一共是 512 字节就是一个扇区的大小, 可以偷懒不用解析格式了。。。

PrintNo:
     resb 2

; ++++++++++++++++++++++++++++++++++++++++
; 代码段
; ++++++++++++++++++++++++++++++++++++++++
section .text
     ; 初始化段寄存器
     intseg 0, 0

     ; 初始化打印宏
     printf_init
     ; 打印欢迎信息
     printf    strWelcome, strWelcomelen
     printfendl

     ; 设置88号中断
exitint:
     ; 88h * 4 = 220h = 544
     mov ax, int88
     mov [220h], ax
     mov ax, 0
     mov [222h], ax

     ; 加载文件索引内容
loadfile:
     ; 加载索引表
     disk_io 40h, 1h, ProgramListSign, 42h, ax         ; 加载 40h(64扇区), 到指定内存
     cmp ax, 0
     ; 加载成功, 检查索引
     je checkmenu
     ; 否则打印出错信息
     printf    strLoadFilErr, strLoadFilErrLen
     printfendl

     jmp $     ; 无限循环

     ; 字符串检查
checkmenu:
     strcmp strProgramListSign, strProgramListSignLen, ProgramListSign, strProgramListSignLen, ax
     cmp ax, 0
     ; 加载成功, 检查索引
     je showmenu
     ; 否则打印出错信息
     printf    strFileInfoErr, strFileInfoErrLen
     printfendl

     jmp $     ; 无限循环

     ; 显示菜单
showmenu:
     printf strProgrmWelcome, strProgrmWelcomeLen
     printfendl

     ; 初始化标号
     mov ax, '.'
     mov [PrintNo+1], ax
     mov ax, '0'

     ; 程序的数量
     mov bx, ProgramListItem
     sub bx, ProgramItemsize
     mov cx, [ProgramCount]
print:
     intseg 0, 0
     ; 打印标号先
     add ax, 1
     mov [PrintNo], ax
     printf PrintNo, 2

     ; 打印文件名
     add bx, ProgramItemsize
     printf bx, ProgramItem.filesize - ProgramItem
     printfendl
     loop print

     ; 等待用户输入
waitinput:
     printf strInputTip, strInputTipLen
     getchar ax
     printfendl
     mov ah, 0
     ; 判断输入的有效
     cmp ax, 49
     jb invalidinput
     cmp ax, 57
     ja invalidinput

     ; 至此认为有效了, 标号
     sub ax, 49
     cmp ax, [ProgramCount]
     jae invalidinput

     mov bl, ProgramItemsize
     mul bl     
     mov bx, ProgramListItem
     add bx, ax
     printf bx, ProgramItem.filesize - ProgramItem
     printfendl

     ; 加载文件
     push bx
     add bx, ProgramItem.fileoffset
     mov ax, [bx]
     pop bx
     add bx, ProgramItem.filesize
     mov bx, [bx]
     disk_io ax, bx, ProgramLoadAddr, 42h, ax         ; 加载 程序
     jmp ProgramLoadAddr

     jmp waitinput

invalidinput:
     printf strInputError, strInputErrorLen
     printfendl
     jmp waitinput

int88:
     ; 这个中断是不返回的，所以要把压栈的flg cs ip抹平
     ; ax 是返回值
     pop bx
     pop bx
     pop bx

     mov ax,0
     mov es, ax
     mov ds, ax
     printfclear
     jmp showmenu


     jmp $     ; 无限循环

