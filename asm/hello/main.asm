.386p
.model flat, stdcall
option casemap:none

include c:\masm32\include\w2k\ntstatus.inc
include c:\masm32\include\w2k\ntddk.inc
include c:\masm32\include\w2k\ntoskrnl.inc
include c:\masm32\include\w2k\ntddkbd.inc
include c:\masm32\Macros\Strings.mac

includelib c:\masm32\lib\wxp\i386\ntoskrnl.lib

public DriverEntry

.const
MSG byte "Hello, world!",0

.code
Unload proc pOurDriver:PDRIVER_OBJECT
  ret
Unload endp

DriverEntry proc pOurDriver:PDRIVER_OBJECT, pOurRegistry:PUNICODE_STRING
  invoke DbgPrint, offset MSG
  mov eax, pOurDriver
  mov (DRIVER_OBJECT PTR [eax]).DriverUnload, offset Unload
  mov eax, STATUS_SUCCESS
  ret
DriverEntry endp
end DriverEntry
.end
