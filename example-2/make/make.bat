nasm "..\\example-2.asm" -d DEBUG -I "..\\..\\lib\\" -f bin -o "_OUT\\example-2.BIN" -l "_OUT\\example-2.LIST"
copy "_OUT\\example-2.bin" "..\\..\\BIN\\example-2.bin"