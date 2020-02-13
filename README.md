# AsmSystem
用汇编写的运行在裸机上的简单系统

##  工程结构:
    MBR\: MBR代码文件
    ProgramLoader\: 由MBR加载的程序，用于加载解析文件列表，加载其他子程序
    example-1\: 子程序一，完成跨段程序的加载与调用
    example-2\: 子程序而，完成程序sleep
    LIB\:   以上程序用到的功能的代码库
    BIN\:   以上文件编译出来的2进制文件的存放位置
    ALL\:   用于支持 make.bat all指令的文件夹
    AsmSystemLoader.bin:    将以上所有程序组合成的镜像文件，将此镜像写到虚拟机的磁盘0扇区可直接运行
    make.bat:   用于编译以上工程的二进制文件
    cleaer.bat: 用于清理以上工程的二进制文件
    ImageMaker.exe: 用于将以上二进制文件生成 AsmSystemLoader.bin镜像文件
    ImgMaker\:  ImageMaker.exe 工程目录

##  编译说明:
    格式：
        make.bat 工程1 [工程2] [工程3] ...
    例子:
        make.bat all
        make.bat MBR ProgramLoader example-1 examlpe2
        make.bat MBR
        make.bat mbr ProgramLoader

##  镜像生成:
    运行 ImageMaker.exe
    说明: MBR 和 ProgramLoader 是必须的, 其他需要打包的子程序在程序中定义


##  AsmSystemLoader.bin格式：
    0扇区:
        MBR
    2-22 扇区：
        ProgramLoader
    64扇区:
        子程序索引
    100扇区:
        子程序1
        [空一扇区]
        子程序2
        [空一扇区]
        。。。。。

## 子程序索引结构:
    typedef struct  _ProgramListItem
    {
        char name[16];
        short size;
        short offset;
    }ProgramListItem;

    typedef struct  _ProgramList
    {
        char sign[6];   //ASMFS 
        short count;
        short per;
        short next;
        ProgramListItem ItemList[25];
    }ProgramList;
