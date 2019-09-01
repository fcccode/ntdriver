#define INITGUID
#include <windows.h>
#include <strsafe.h>
#include <setupapi.h>
#include <stdio.h>
#include <stdlib.h>

int __cdecl main(int argc, char* argv[])
{
  HANDLE hFile = NULL;
  DWORD dwRet = 0;
  char szBuffer[255]={0};

  hFile = CreateFile("\\\\.\\MyDriver", GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);
  if(hFile == INVALID_HANDLE_VALUE){
    printf("failed to open mydriver");
    return 1;
  }

  strncpy(szBuffer, "I am error", sizeof(szBuffer));
  WriteFile(hFile, szBuffer, strlen(szBuffer) + 1, &dwRet, NULL);
  printf("WR: %s, %d\n", szBuffer, dwRet);

  memset(szBuffer, 0, sizeof(szBuffer));
  ReadFile(hFile, szBuffer, sizeof(szBuffer), &dwRet, NULL);
  printf("RD: %s, %d\n", szBuffer, dwRet);
  CloseHandle(hFile);
  return 0;
}
