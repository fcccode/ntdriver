#define INITGUID
#include <windows.h>
#include <strsafe.h>
#include <setupapi.h>
#include <stdio.h>
#include <stdlib.h>

int __cdecl main(int argc, char* argv[])
{
  DWORD dwRet=0;
  char szBuffer[32]={0};
  HANDLE hFile=INVALID_HANDLE_VALUE;

  hFile = CreateFile("\\\\.\\MyDriver", GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);
  if(hFile == INVALID_HANDLE_VALUE){
    printf("failed to open mydriver");
    return -1;
  }
  WriteFile(hFile, szBuffer, sizeof(szBuffer), &dwRet, NULL);
  ReadFile(hFile, szBuffer, sizeof(szBuffer), &dwRet, NULL);
  CloseHandle(hFile);
  return 0;
}
