nasm "..\\ProgramLoader.asm" -d DEBUG -I "..\\..\\lib\\" -f bin -o "_OUT\\ProgramLoader.BIN" -l "_OUT\\ProgramLoader.LIST"
copy "_OUT\\ProgramLoader.bin" "..\\..\\BIN\\ProgramLoader.bin"