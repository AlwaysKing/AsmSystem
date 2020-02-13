// ImgMaker.cpp : 此文件包含 "main" 函数。程序执行将在此处开始并结束。
//

#include <iostream>
#include <windows.h>

typedef struct  _ProgramListItem
{
	char name[16];
	short size;
	short offset;
}ProgramListItem;

typedef struct  _ProgramList
{
	char sign[6];
	short count;
	short per;
	short next;
	ProgramListItem ItemList[25];
}ProgramList;

LPCSTR lpszExampleList[] = {
	"example-1.bin",
	"example-2.bin",
	""
};

int main()
{
    HANDLE hFile = CreateFile(L"AsmSystemImg.bin", FILE_GENERIC_READ | FILE_GENERIC_WRITE, FILE_SHARE_READ, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE) {
        std::cout << "创建文件失败\r\n";
    }

// 加载MBR
    {
        HANDLE hmbrfile = CreateFile(L".\\bin\\mbr.bin", FILE_GENERIC_READ | FILE_GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
        if (hmbrfile == INVALID_HANDLE_VALUE) {
            goto end;
        }

        DWORD filesize = GetFileSize(hmbrfile, NULL);
        if (filesize > 0x1b8) {
            std::cout << "MBR 文件太大了\r\n";
            CloseHandle(hmbrfile);
            goto end;
        }

        char buff[512];
        ZeroMemory(buff, 512);
        buff[510] = 0x55;
        buff[511] = 0xaa;
        DWORD dwread = 0;
        if (!ReadFile(hmbrfile, buff, filesize, &dwread, NULL) || dwread != filesize) {
			std::cout << "MBR 文件读取失败\r\n";
			CloseHandle(hmbrfile);
            goto end;
        }

        if (!WriteFile(hFile, buff, 512, &dwread, NULL) || dwread != 512) {
			std::cout << "MBR 写入失败\r\n";
			CloseHandle(hmbrfile);
			goto end;
        }

		CloseHandle(hmbrfile);
    }


// 加载Programloader
	{
		HANDLE hloaderfile = CreateFile(L".\\bin\\programloader.bin", FILE_GENERIC_READ | FILE_GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
		if (hloaderfile == INVALID_HANDLE_VALUE) {
			goto end;
		}

		DWORD filesize = GetFileSize(hloaderfile, NULL);
		if (filesize > 10240) {
			std::cout << "ProgramLoader 文件太大了\r\n";
			CloseHandle(hloaderfile);
			goto end;
		}

		PCHAR buff = (PCHAR)LocalAlloc(LPTR, filesize);
		if (buff == NULL) {
			std::cout << "ProgramLoader 申请内存失败\r\n";
			CloseHandle(hloaderfile);
			goto end;
		}

		ZeroMemory(buff, filesize);

		DWORD dwread = 0;
		if (!ReadFile(hloaderfile, buff, filesize, &dwread, NULL) || dwread != filesize) {
			std::cout << "ProgramLoader 文件读取失败\r\n";
			CloseHandle(hloaderfile);
			LocalFree(buff);
			goto end;
		}

		SetFilePointer(hFile, 1024, 0, FILE_BEGIN);

		if (!WriteFile(hFile, buff, filesize, &dwread, NULL) || dwread != filesize) {
			std::cout << "ProgramLoader 写入失败\r\n";
			CloseHandle(hloaderfile);
			LocalFree(buff);
			goto end;
		}

		CloseHandle(hloaderfile);
		LocalFree(buff);
	}


// 加载其他程序
	{
		DWORD dwread = 0;
		DWORD FileOffset = 100 * 512;
		
		ProgramList list;
		ZeroMemory(&list, sizeof(list));
		strncpy_s(list.sign, "ASMFS", 6);
		
		// 实际文件从100扇区开始
		for (int i = 0; i < 0xffff; i++)
		{
			if ((FileOffset/512) > 0xffff) {
				std::cout << lpszExampleList[i] << "没有空间了\r\n";
				break;
			}

			if (strlen(lpszExampleList[i]) == 0) {
				break;
			}

			char FilePath[MAX_PATH];
			strncpy_s(FilePath, ".\\bin\\", MAX_PATH);
			strncat_s(FilePath, (char*)lpszExampleList[i], MAX_PATH -6);
			HANDLE hExample = CreateFileA(FilePath, FILE_GENERIC_READ | FILE_GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
			if (hExample == INVALID_HANDLE_VALUE) {
				std::cout << lpszExampleList[i] << "文件打开失败\r\n";
				continue;
			}

			DWORD filesize = GetFileSize(hExample, NULL);
			if (filesize > 0xffff) {
				std::cout << lpszExampleList[i] << "文件太大了\r\n";
				CloseHandle(hExample);
				continue;
			}

			PCHAR buff = (PCHAR)LocalAlloc(LPTR, filesize);
			if (buff == NULL) {
				std::cout << lpszExampleList[i] << "申请内存失败\r\n";
				CloseHandle(hExample);
				continue;
			}

			ZeroMemory(buff, filesize);

			if (!ReadFile(hExample, buff, filesize, &dwread, NULL) || dwread != filesize) {
				std::cout << lpszExampleList[i] << "文件读取失败\r\n";
				CloseHandle(hExample);
				LocalFree(buff);
				continue;
			}

			SetFilePointer(hFile, FileOffset, 0, FILE_BEGIN);
			if (!WriteFile(hFile, buff, filesize, &dwread, NULL) || dwread != filesize) {
				std::cout << lpszExampleList[i] << "写入失败\r\n";
				CloseHandle(hExample);
				LocalFree(buff);
				continue;
			}

			CloseHandle(hExample);
			LocalFree(buff);

			// 填充结构
			int length = min(16, strlen(lpszExampleList[i]));
			strncpy_s(list.ItemList[i].name, lpszExampleList[i], length);
			ZeroMemory(list.ItemList[i].name + length, 16 - length);
			list.ItemList[i].offset = FileOffset / 512;
			list.ItemList[i].size = filesize / 512;	
			if (filesize % 512 != 0) {
				list.ItemList[i].size++;
			}
			list.count++;

			// 计算新边界
			FileOffset = (list.ItemList[i].offset + list.ItemList[i].size + 1) * 512;
		}

		SetFilePointer(hFile, 64 * 512, 0, FILE_BEGIN);		
		if (!WriteFile(hFile, &list, sizeof(list), &dwread, NULL) || dwread != sizeof(list)) {
			std::cout << "写入List失败\r\n";
		}
	}


end:
    if (hFile != INVALID_HANDLE_VALUE) {
        CloseHandle(hFile);
    }

}
