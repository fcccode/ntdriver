.386p
.model flat, stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\masm32.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\msvcrt.inc
include c:\masm32\Macros\Strings.mac
include c:\masm32\include\kernel32.inc

includelib c:\masm32\lib\user32.lib
includelib c:\masm32\lib\masm32.lib
includelib c:\masm32\lib\msvcrt.lib
includelib c:\masm32\lib\kernel32.lib

.const
DEV_NAME  db "\\.\MyDriver",0
ERR_OPEN  db "failed to open mydriver",10,13,0
MSG_SEND  db "I am error",0
MSG_WRITE db "WR: %s",10,13,0
MSG_READ  db "RD: %s",10,13,0
MSG_LEN   db "Length: %d",10,13,0

.data?
hFile     dd ?
dwRet     dd ?
szBuffer  db 255 dup(?)

.code
start:
  invoke CreateFile, offset DEV_NAME, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
  .if eax == INVALID_HANDLE_VALUE
    invoke crt_printf, offset ERR_OPEN
    invoke ExitProcess, -1
  .endif
  mov hFile, eax

  invoke wsprintf, offset szBuffer, offset MSG_SEND
  invoke StrLen, offset szBuffer
  inc eax
  mov dwRet, eax
  invoke crt_printf, offset MSG_WRITE, offset szBuffer
  invoke crt_printf, offset MSG_LEN, dwRet
  invoke WriteFile, hFile, offset szBuffer, dwRet, offset dwRet, 0
  invoke crt_memset, offset szBuffer, 0, 255
  invoke ReadFile, hFile, offset szBuffer, 255, offset dwRet, 0
  invoke crt_printf, offset MSG_READ, offset szBuffer
  invoke crt_printf, offset MSG_LEN, dwRet
  invoke CloseHandle, hFile
  invoke ExitProcess, 0
end start
