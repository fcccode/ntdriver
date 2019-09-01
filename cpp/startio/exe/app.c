#define INITGUID
#include <windows.h>
#include <winioctl.h>
#include <strsafe.h>
#include <setupapi.h>
#include <stdio.h>
#include <stdlib.h>

int __cdecl main(int argc, char* argv[])
{
  DWORD len=0;
  DWORD dwRet=0;
  HANDLE hFile=NULL;
  char szBuffer[255]={0};
 
  hFile = CreateFile("\\\\.\\MyDriver", GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);
  if (hFile == INVALID_HANDLE_VALUE) {
    printf("failed to open mydriver\n");
    return -1;
  }

  sprintf_s(szBuffer, sizeof(szBuffer), "I am error");
  len = strlen(szBuffer)+1;
  printf("WR: %s\n", szBuffer);
  printf("Length: %d\n", len);
  WriteFile(hFile, szBuffer, len, &dwRet, NULL);

  memset(szBuffer, 0, sizeof(szBuffer));
  ReadFile(hFile, szBuffer, sizeof(szBuffer), &dwRet, NULL);
  printf("RD: %s\n", szBuffer);
  printf("Length: %d\n", dwRet);
  CloseHandle(hFile);
  return 0;
}
