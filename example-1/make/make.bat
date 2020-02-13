nasm "..\\example-1.asm" -d DEBUG -I "..\\..\\lib\\" -f bin -o "_OUT\\example-1.BIN" -l "_OUT\\example-1.LIST"
copy "_OUT\\example-1.bin" "..\\..\\BIN\\example-1.bin"