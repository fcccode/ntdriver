#define INITGUID
#include <windows.h>
#include <winioctl.h>
#include <strsafe.h>
#include <setupapi.h>
#include <stdio.h>
#include <stdlib.h>

#define IOCTL_TEST CTL_CODE(FILE_DEVICE_UNKNOWN, 0x800, METHOD_BUFFERED, FILE_ANY_ACCESS)
 
int __cdecl main(int argc, char* argv[])
{
  DWORD dwRet = 0;
  HANDLE hFile = NULL;

  hFile = CreateFile("\\\\.\\MyDriver", GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);
  if (hFile == INVALID_HANDLE_VALUE) {
    printf("failed to open mydriver");
    return 1;
  }
  DeviceIoControl(hFile, IOCTL_TEST, NULL, 0, NULL, 0, &dwRet, NULL);  
  CloseHandle(hFile);
  return 0;
}

