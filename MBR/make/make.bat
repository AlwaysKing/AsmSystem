nasm "..\\mbr.asm" -d DEBUG -I "..\\..\\lib\\" -f bin -o "_OUT\\MBR.BIN" -l "_OUT\\MBR.LIST"
copy "_OUT\\MBR.bin" "..\\..\\BIN\\MBR.bin"