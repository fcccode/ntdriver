#define INITGUID
#include <windows.h>
#include <winioctl.h>
#include <strsafe.h>
#include <setupapi.h>
#include <stdio.h>
#include <stdlib.h>

#define IOCTL_SET CTL_CODE(FILE_DEVICE_UNKNOWN, 0x800, METHOD_NEITHER, FILE_ANY_ACCESS)
#define IOCTL_GET CTL_CODE(FILE_DEVICE_UNKNOWN, 0x801, METHOD_NEITHER, FILE_ANY_ACCESS)

int __cdecl main(int argc, char* argv[])
{
  DWORD dwRet = 0;
  HANDLE hFile = NULL;
  char szBuffer[255]={"I am error"};

  hFile = CreateFile("\\\\.\\MyDriver", GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);
  if (hFile == INVALID_HANDLE_VALUE) {
    printf("failed to open mydriver");
    return 1;
  }
  printf("SET: %s, %d\n", szBuffer, strlen(szBuffer)+1);
  DeviceIoControl(hFile, IOCTL_SET, szBuffer, strlen(szBuffer)+1, NULL, 0, &dwRet, NULL);
  memset(szBuffer, 0, sizeof(szBuffer));
  DeviceIoControl(hFile, IOCTL_GET, NULL, 0, szBuffer, sizeof(szBuffer), &dwRet, NULL);
  printf("GET: %s, %d\n", szBuffer, dwRet);
  CloseHandle(hFile);
  return 0;
}
