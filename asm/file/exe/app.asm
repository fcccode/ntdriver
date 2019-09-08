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
DEVNAME db "\\.\MyDriver",0
ERR_MSG db "failed to open mydriver",0

.data?
hFile    dd ?
dwRet    dd ?
szBuffer db 255 dup(?)

.code
start:
  invoke CreateFile, offset DEVNAME, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
  .if eax == INVALID_HANDLE_VALUE
    invoke crt_printf, offset ERR_MSG
    invoke ExitProcess, -1
  .endif
  
  mov hFile, eax
  invoke WriteFile, hFile, offset szBuffer, 255, offset dwRet, 0
  invoke ReadFile, hFile, offset szBuffer, 255, offset dwRet, 0
  invoke CloseHandle, hFile
  invoke ExitProcess, 0
  
end start
