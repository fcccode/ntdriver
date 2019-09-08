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

OurDeviceExtension struct
  bExit    DWORD ?
  pNextDev PDEVICE_OBJECT ?
  pThread  PVOID ?          
OurDeviceExtension ends

IOCTL_START equ CTL_CODE(FILE_DEVICE_UNKNOWN, 800h, METHOD_BUFFERED, FILE_ANY_ACCESS)
IOCTL_STOP  equ CTL_CODE(FILE_DEVICE_UNKNOWN, 801h, METHOD_BUFFERED, FILE_ANY_ACCESS)

.const
DEV_NAME  word "\","D","e","v","i","c","e","\","M","y","D","r","i","v","e","r",0
SYM_NAME  word "\","D","o","s","D","e","v","i","c","e","s","\","M","y","D","r","i","v","e","r",0
MSG_START byte "IOCTL_START",0 
MSG_STOP  byte "IOCTL_STOP",0

.code
MyThread proc pParam:DWORD
  local pdx:DWORD
  local pStr:DWORD
  local stTime:LARGE_INTEGER
  
  or stTime.HighPart, -1
  mov stTime.LowPart, -10000000

  invoke IoGetCurrentProcess
  add eax, 174h
  mov pStr, eax
  invoke DbgPrint, $CTA0("Current process: %s"), pStr

  mov eax, pParam
  mov eax, (DEVICE_OBJECT PTR [eax]).DeviceExtension
  push eax
  pop pdx
  mov eax, (OurDeviceExtension PTR [eax]).bExit
  .while(eax != TRUE)
      invoke KeDelayExecutionThread, KernelMode, FALSE, addr stTime
      invoke DbgPrint, $CTA0("Sleep 1s")
      mov eax, pdx
      mov eax, (OurDeviceExtension PTR [eax]).bExit
  .endw
  invoke DbgPrint, $CTA0("Exit MyThread")
  invoke PsTerminateSystemThread, STATUS_SUCCESS
  ret
MyThread endp

IrpOpenClose proc pOurDevice:PDEVICE_OBJECT, pIrp:PIRP
  IoGetCurrentIrpStackLocation pIrp
  movzx eax, (IO_STACK_LOCATION PTR [eax]).MajorFunction
  .if eax == IRP_MJ_CREATE
    invoke DbgPrint, $CTA0("IRP_MJ_CREATE")
  .elseif eax == IRP_MJ_CLOSE
    invoke DbgPrint, $CTA0("IRP_MJ_CLOSE")
  .endif

  mov eax, pIrp
  and (_IRP PTR [eax]).IoStatus.Information, 0
  mov (_IRP PTR [eax]).IoStatus.Status, STATUS_SUCCESS
  fastcall IofCompleteRequest, pIrp, IO_NO_INCREMENT
  mov eax, STATUS_SUCCESS
  ret
IrpOpenClose endp

IrpIOCTL proc pOurDevice:PDEVICE_OBJECT, pIrp:PIRP
  local pdx:PTR OurDeviceExtension
  local pBuf:DWORD
  local hThread:DWORD
  local pThread:PVOID

  mov eax, pOurDevice
  push (DEVICE_OBJECT PTR [eax]).DeviceExtension
  pop pdx

  IoGetCurrentIrpStackLocation pIrp
  mov eax, (IO_STACK_LOCATION PTR [eax]).Parameters.DeviceIoControl.IoControlCode
  .if eax == IOCTL_START
    invoke DbgPrint, offset MSG_START

    mov eax, pdx
    and (OurDeviceExtension PTR [eax]).bExit, 0

    ; user thread
    invoke PsCreateSystemThread, addr hThread, THREAD_ALL_ACCESS, NULL, -1, NULL, offset MyThread, pOurDevice
    
    ; system thread
    ;invoke PsCreateSystemThread, addr hThread, THREAD_ALL_ACCESS, NULL, NULL, NULL, offset MyThread, pOurDevice
    
    .if eax == STATUS_SUCCESS
      mov eax, pdx
      invoke ObReferenceObjectByHandle, hThread, THREAD_ALL_ACCESS, NULL, KernelMode, addr (OurDeviceExtension PTR [ebx]).pThread, NULL
      invoke ZwClose, hThread
    .endif

  .elseif eax == IOCTL_STOP
    invoke DbgPrint, offset MSG_STOP
    mov eax, pdx
    mov (OurDeviceExtension PTR [eax]).bExit, TRUE
    push (OurDeviceExtension PTR [eax]).pThread
    pop pThread
    mov eax, pThread
    .if eax != NULL
      invoke KeWaitForSingleObject, pThread, Executive, KernelMode, FALSE, NULL
      invoke ObDereferenceObject, pThread
    .endif
  .endif

  mov eax, pIrp
  mov (_IRP PTR [eax]).IoStatus.Status, STATUS_SUCCESS
  and (_IRP PTR [eax]).IoStatus.Information, 0
  fastcall IofCompleteRequest, pIrp, IO_NO_INCREMENT
  mov eax, STATUS_SUCCESS
  ret
IrpIOCTL endp

Unload proc pOurDriver:PDRIVER_OBJECT
  local szSymName:UNICODE_STRING
           
  invoke RtlInitUnicodeString, addr szSymName, offset SYM_NAME
  invoke IoDeleteSymbolicLink, addr szSymName
           
  mov eax, pOurDriver
  invoke IoDeleteDevice, (DRIVER_OBJECT PTR [eax]).DeviceObject
  ret
Unload endp
    
DriverEntry proc pOurDriver:PDRIVER_OBJECT, pOurRegistry:PUNICODE_STRING
  local pOurDevice:PDEVICE_OBJECT
  local suDevName:UNICODE_STRING
  local szSymName:UNICODE_STRING
      
  mov eax, pOurDriver
  mov (DRIVER_OBJECT PTR [eax]).MajorFunction[IRP_MJ_CREATE * (sizeof PVOID)], offset IrpOpenClose
  mov (DRIVER_OBJECT PTR [eax]).MajorFunction[IRP_MJ_CLOSE  * (sizeof PVOID)], offset IrpOpenClose
  mov (DRIVER_OBJECT PTR [eax]).MajorFunction[IRP_MJ_DEVICE_CONTROL * (sizeof PVOID)], offset IrpIOCTL
  mov (DRIVER_OBJECT PTR [eax]).DriverUnload, offset Unload
      
  invoke RtlInitUnicodeString, addr suDevName, offset DEV_NAME
  invoke RtlInitUnicodeString, addr szSymName, offset SYM_NAME
  invoke IoCreateDevice, pOurDriver, sizeof OurDeviceExtension, addr suDevName, FILE_DEVICE_UNKNOWN, 0, FALSE, addr pOurDevice
  .if eax == STATUS_SUCCESS
    mov eax, pOurDevice
    or (DEVICE_OBJECT PTR [eax]).Flags, DO_BUFFERED_IO
    and (DEVICE_OBJECT PTR [eax]).Flags, not DO_DEVICE_INITIALIZING
    invoke IoCreateSymbolicLink, addr szSymName, addr suDevName
  .endif
  ret
DriverEntry endp
end DriverEntry
.end
