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
  pNextDev  PDEVICE_OBJECT ?
  stQueue   LIST_ENTRY     <>
  stDPC     KDPC           <>
  stTime    KTIMER         <>
OurDeviceExtension ends

IOCTL_QUEUE   equ CTL_CODE(FILE_DEVICE_UNKNOWN, 800h, METHOD_BUFFERED, FILE_ANY_ACCESS)
IOCTL_PROCESS equ CTL_CODE(FILE_DEVICE_UNKNOWN, 801h, METHOD_BUFFERED, FILE_ANY_ACCESS)

.const
DEV_NAME    word "\","D","e","v","i","c","e","\","M","y","D","r","i","v","e","r",0
SYM_NAME    word "\","D","o","s","D","e","v","i","c","e","s","\","M","y","D","r","i","v","e","r",0
MSG_QUEUE   byte "IOCTL_QUEUE",0
MSG_PROCESS byte "IOCTL_PROCESS",0

.code
OnTimer proc pDpc:PKDPC, pContext:PVOID, pArg1:PVOID, PArg2:PVOID
  mov eax, pContext
  mov eax, (DEVICE_OBJECT PTR [eax]).DeviceExtension
  lea eax, (OurDeviceExtension PTR [eax]).stQueue
  IsListEmpty eax
  .if eax == TRUE
    mov eax, pContext
    mov eax, (DEVICE_OBJECT PTR [eax]).DeviceExtension
    invoke KeCancelTimer, addr (OurDeviceExtension PTR [eax]).stTime
    invoke DbgPrint, $CTA0("Finish")
  .else
    mov eax, pContext
    mov eax, (DEVICE_OBJECT PTR [eax]).DeviceExtension
    lea eax, (OurDeviceExtension PTR [eax]).stQueue
    RemoveHeadList eax
    
    ; CONTAINING_RECORD 
    sub eax, _IRP.Tail.Overlay.ListEntry
    mov (_IRP PTR [eax]).IoStatus.Status, STATUS_SUCCESS
    push 0
    pop (_IRP PTR [eax]).IoStatus.Information
    fastcall IofCompleteRequest, eax, IO_NO_INCREMENT
    invoke DbgPrint, $CTA0("Complete Irp %d"), _IRP.Tail.Overlay.ListEntry
  .endif
  ret
OnTimer endp

IrpOpenClose proc pDevObj:PDEVICE_OBJECT, pIrp:PIRP
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

IrpIOCTL proc uses ebx ecx pOurDevice:PDEVICE_OBJECT, pIrp:PIRP
  local pdx:PTR Dev_Ext
  local stTimePeriod:LARGE_INTEGER

  mov eax, pOurDevice
  push (DEVICE_OBJECT PTR [eax]).DeviceExtension
  pop pdx

  IoGetCurrentIrpStackLocation pIrp
  mov eax, (IO_STACK_LOCATION PTR [eax]).Parameters.DeviceIoControl.IoControlCode
  .if eax == IOCTL_QUEUE
    invoke DbgPrint, offset MSG_QUEUE

    mov ebx, pdx
    lea ebx, (OurDeviceExtension PTR [ebx]).stQueue
    mov ecx, pIrp
    lea ecx, (_IRP PTR [ecx]).Tail.Overlay.ListEntry
    InsertHeadList ebx, ecx
    IoMarkIrpPending pIrp
    mov eax, STATUS_PENDING
    ret
  .elseif eax == IOCTL_PROCESS
    invoke DbgPrint, offset MSG_PROCESS
    
    or stTimePeriod.HighPart, -1
    mov stTimePeriod.LowPart, -10000000
    mov ebx, pdx
    invoke KeSetTimerEx, addr (OurDeviceExtension PTR [ebx]).stTime, stTimePeriod.LowPart, stTimePeriod.HighPart, 10, addr (OurDeviceExtension PTR [ebx]).stDPC
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
    
    mov eax, pOurDevice
    mov eax, (DEVICE_OBJECT PTR [eax]).DeviceExtension
    lea eax, (OurDeviceExtension PTR [eax]).stQueue
    InitializeListHead eax

    mov eax, pOurDevice
    mov eax, (DEVICE_OBJECT PTR [eax]).DeviceExtension
    invoke KeInitializeTimer, addr (OurDeviceExtension ptr [eax]).stTime

    mov eax, pOurDevice
    mov eax, (DEVICE_OBJECT PTR [eax]).DeviceExtension
    invoke KeInitializeDpc, addr (OurDeviceExtension ptr [eax]).stDPC, offset OnTimer, pOurDevice
    invoke IoCreateSymbolicLink, addr szSymName, addr suDevName
  .endif
  ret
DriverEntry endp
end DriverEntry
.end
