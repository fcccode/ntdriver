.386p
.model flat, stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\masm32.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\msvcrt.inc
include c:\masm32\include\kernel32.inc

includelib c:\masm32\lib\user32.lib
includelib c:\masm32\lib\masm32.lib
includelib c:\masm32\lib\msvcrt.lib
includelib c:\masm32\lib\kernel32.lib

.const
DEV_NAME db "\\.\MyDriver",0
MSG_ERR  db "failed to open mydriver",0
MSG_SEND db "I am error",0
MSG_WR   db "WR: %s, %d",10,13,0
MSG_RD   db "RD: %s, %d",10,13,0

.data?
hFile    dd ?
dwRet    dd ?
szBuffer db 255 dup(?)

.code
start:
  invoke CreateFile, offset DEV_NAME, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
  .if eax == INVALID_HANDLE_VALUE
    invoke crt_printf, offset MSG_ERR
    invoke ExitProcess, -1
  .endif
  
  mov hFile, eax
  invoke StrLen, offset MSG_SEND
  inc eax
  mov dwRet, eax
  invoke crt_printf, offset MSG_WR, offset MSG_SEND, dwRet
  invoke WriteFile, hFile, offset MSG_SEND, dwRet, offset dwRet, 0
  invoke crt_memset, offset szBuffer, 0, 255
  invoke ReadFile, hFile, offset szBuffer, 255, offset dwRet, 0
  invoke crt_printf, offset MSG_RD, offset szBuffer, dwRet
  invoke CloseHandle, hFile
  invoke ExitProcess, 0

end start

