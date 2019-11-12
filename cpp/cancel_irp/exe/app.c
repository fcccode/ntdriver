#define INITGUID
#include <windows.h>
#include <winioctl.h>
#include <strsafe.h>
#include <setupapi.h>
#include <stdio.h>
#include <stdlib.h>

#define IOCTL_QUEUE   CTL_CODE(FILE_DEVICE_UNKNOWN, 0x800, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_PROCESS CTL_CODE(FILE_DEVICE_UNKNOWN, 0x801, METHOD_BUFFERED, FILE_ANY_ACCESS)

int __cdecl main(int argc, char* argv[])
{
  int i=0;
  DWORD dwRet = 0;
  HANDLE hFile = NULL;
  OVERLAPPED ov[3]={0};

  hFile = CreateFile("\\\\.\\MyDriver", GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, FILE_FLAG_OVERLAPPED | FILE_ATTRIBUTE_NORMAL, NULL);
  if (hFile == INVALID_HANDLE_VALUE) {
    printf("failed to open mydriver\n");
    return -1;
  }
  for(i=0; i<3; i++){
    memset(&ov[i], 0, sizeof(ov[i]));
    ov[i].hEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    printf("queue event\n");
    DeviceIoControl(hFile, IOCTL_QUEUE, NULL, 0, NULL, 0, &dwRet, &ov[i]);
  }
  printf("process all of events\n");
  DeviceIoControl(hFile, IOCTL_PROCESS, NULL, 0, NULL, 0, &dwRet, NULL);
  Sleep(1000);
  CancelIo(hFile);
  for(i=0; i<3; i++){
    WaitForSingleObject(ov[i].hEvent, INFINITE);
    CloseHandle(ov[i].hEvent);
    printf("wait complete\n");
  }
  CloseHandle(hFile);
  return 0;
}
