.386p
.model flat, stdcall
option casemap:none
 
include c:\masm32\include\windows.inc
include c:\masm32\include\masm32.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\msvcrt.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\w2k\ntddkbd.inc
include c:\masm32\Macros\Strings.mac
  
includelib c:\masm32\lib\user32.lib
includelib c:\masm32\lib\masm32.lib
includelib c:\masm32\lib\msvcrt.lib
includelib c:\masm32\lib\kernel32.lib
 
IOCTL_QUEUE   equ CTL_CODE(FILE_DEVICE_UNKNOWN, 800h, METHOD_BUFFERED, FILE_ANY_ACCESS)
IOCTL_PROCESS equ CTL_CODE(FILE_DEVICE_UNKNOWN, 801h, METHOD_BUFFERED, FILE_ANY_ACCESS)
 
.const
DEV_NAME db "\\.\MyDriver",0
 
.data?
cnt   dd ?
hFile dd ?
dwRet dd ?
event dd 3 dup(?)
ov OVERLAPPED <?>

.code
start:
  invoke CreateFile, offset DEV_NAME, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, 0, OPEN_EXISTING, FILE_FLAG_OVERLAPPED or FILE_ATTRIBUTE_NORMAL, 0
  .if eax == INVALID_HANDLE_VALUE
    invoke crt_printf, $CTA0("failed to open mydriver\n")
    invoke ExitProcess, -1
  .endif
  mov hFile, eax
  invoke crt_memset, offset ov, 0, sizeof OVERLAPPED
  
  mov cnt, 3
  .while cnt > 0
    invoke CreateEvent, NULL, TRUE, FALSE, NULL
    push eax
    pop ov.hEvent
    
    mov ecx, cnt
    mov edi, offset event
    mov [edi + ecx * 4], eax
    
    invoke crt_printf, $CTA0("queue event\n")
    invoke DeviceIoControl, hFile, IOCTL_QUEUE, NULL, 0, NULL, 0, offset dwRet, offset ov
    invoke CloseHandle, ov.hEvent
    sub cnt, 1
  .endw
  
  invoke crt_printf, $CTA0("process all of events\n")
  invoke DeviceIoControl, hFile, IOCTL_PROCESS, NULL, 0, NULL, 0, offset dwRet, NULL
  invoke Sleep, 1000
  invoke CancelIo, hFile
  
  mov cnt, 3
  .while cnt > 0
    mov ecx, cnt
    mov edi, offset event
    mov eax, [edi + ecx * 4]
     
    push eax
    pop ov.hEvent
     
    invoke WaitForSingleObject, ov.hEvent, INFINITE
    invoke CloseHandle, ov.hEvent
    invoke crt_printf, $CTA0("wait complete\n")
    sub cnt, 1
  .endw
  
  invoke CloseHandle, hFile
  invoke ExitProcess, 0
end start
