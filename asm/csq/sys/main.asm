.386p
.model flat, stdcall
option casemap:none

include c:\masm32\include\w2k\hal.inc
include c:\masm32\include\w2k\ntstatus.inc
include c:\masm32\include\w2k\ntddk.inc
include c:\masm32\include\w2k\ntoskrnl.inc
include c:\masm32\include\w2k\ntddkbd.inc
include c:\masm32\include\wxp\csq.inc
include c:\masm32\Macros\Strings.mac
includelib c:\masm32\lib\w2k\hal.lib
includelib c:\masm32\lib\w2k\ntoskrnl.lib
includelib c:\masm32\lib\wxp\i386\csq.lib

public DriverEntry

OurDeviceExtension struct
  pNextDev PDEVICE_OBJECT ?
  stQueue  LIST_ENTRY     <>
  stDPC    KDPC           <>
  stTime   KTIMER         <>
  stCsq    IO_CSQ         <>
  stLock   KSPIN_LOCK     <>
OurDeviceExtension ends

IOCTL_QUEUE   equ CTL_CODE(FILE_DEVICE_UNKNOWN, 800h, METHOD_BUFFERED, FILE_ANY_ACCESS)
IOCTL_PROCESS equ CTL_CODE(FILE_DEVICE_UNKNOWN, 801h, METHOD_BUFFERED, FILE_ANY_ACCESS)

.const
DEV_NAME    word "\","D","e","v","i","c","e","\","M","y","D","r","i","v","e","r",0
SYM_NAME    word "\","D","o","s","D","e","v","i","c","e","s","\","M","y","D","r","i","v","e","r",0
MSG_QUEUE   byte "IOCTL_QUEUE",0
MSG_PROCESS byte "IOCTL_PROCESS",0

.code
CsqInsertIrp proc uses ebx ecx pCsqInfo:PIO_CSQ, pIrp:PIRP
  local pdx:PTR DevExt
  
  invoke DbgPrint, $CTA0("CsqInsertIrp")
  
  ; CONTAINING_RECORD 
  mov eax, pCsqInfo
  sub eax, OurDeviceExtension.stCsq
  mov pdx, eax

  mov ebx, pdx
  lea ebx, (OurDeviceExtension PTR [ebx]).stQueue
  mov ecx, pIrp
  lea ecx, (_IRP PTR [ecx]).Tail.Overlay.ListEntry
  InsertTailList ebx, ecx
  ret
CsqInsertIrp endp

CsqRemoveIrp proc pCsqInfo:PIO_CSQ, pIrp:PIRP
  invoke DbgPrint, $CTA0("CsqRemoveIrp")
  mov eax, pIrp
  lea eax, (_IRP PTR [eax]).Tail.Overlay.ListEntry
  RemoveEntryList eax
  ret
CsqRemoveIrp endp

CsqCompleteCanceledIrp proc pCsqInfo:PIO_CSQ, pIrp:PIRP
  local pdx:PTR OurDeviceExtension
  
  invoke DbgPrint, $CTA0("CsqCompleteCanceledIrp")
  
  ;// CONTAINING_RECORD 
  mov eax, pCsqInfo
  sub eax, OurDeviceExtension.stCsq
  mov pdx, eax

  mov eax, pIrp
  mov (_IRP PTR [eax]).IoStatus.Status, STATUS_CANCELLED
  and (_IRP PTR [eax]).IoStatus.Information, 0
  fastcall IofCompleteRequest, eax, IO_NO_INCREMENT
  ret
CsqCompleteCanceledIrp endp 

CsqPeekNextIrp proc uses ebx pCsqInfo:PIO_CSQ, pIrp:PIRP, pPeekContext:PVOID
  local pdx:PTR OurDeviceExtension
  local listHead:PTR LIST_ENTRY
  local nextEntry:PTR LIST_ENTRY
  local nextIrp:PTR _IRP
  local irpStack:PIO_STACK_LOCATION
  
  invoke DbgPrint, $CTA0("CsqPeekNextIrp")
  mov nextIrp, NULL
  
  ; CONTAINING_RECORD 
  mov eax, pCsqInfo
  sub eax, OurDeviceExtension.stCsq
  mov pdx, eax
  
  mov eax, pdx
  lea eax, (OurDeviceExtension PTR [eax]).stQueue
  mov listHead, eax
  
  mov eax, pIrp
  .if eax == NULL
    mov eax, listHead
    push (LIST_ENTRY PTR [eax]).Flink
    pop nextEntry 
  .elseif
    mov eax, pIrp
    push (_IRP PTR [eax]).Tail.Overlay.ListEntry.Flink
    pop nextEntry 
  .endif
  
  mov eax, nextEntry
  mov ebx, listHead
  .while eax != ebx
    ; nextIrp = CONTAINING_RECORD(nextEntry, IRP, Tail.Overlay.ListEntry)
    mov eax, nextEntry
    sub eax, _IRP.Tail.Overlay.ListEntry
    mov nextIrp, eax

    IoGetCurrentIrpStackLocation nextIrp
    mov irpStack, eax
    
    mov eax, pPeekContext
    .if eax != NULL
      mov eax, irpStack
      mov eax, (IO_STACK_LOCATION PTR [eax]).FileObject
      mov ebx, pPeekContext
      .if eax == ebx
        .break
      .endif
    .elseif
      .break
    .endif
    
    mov nextIrp, NULL
    mov eax, nextEntry
    mov eax, (LIST_ENTRY PTR [eax]).Flink
    mov nextEntry, eax
    
    mov eax, nextEntry
    mov ebx, listHead
  .endw
  mov eax, nextIrp
  ret
CsqPeekNextIrp endp

CsqAcquireLock proc uses ecx pCsqInfo:PIO_CSQ, pIrql:PKIRQL
  local pdx:PTR OurDeviceExtension
  
  invoke DbgPrint, $CTA0("CsqAcquireLock")
  
  ; CONTAINING_RECORD 
  mov eax, pCsqInfo
  sub eax, OurDeviceExtension.stCsq
  mov pdx, eax

  mov eax, pdx
  lea ecx, (OurDeviceExtension PTR [eax]).stLock
  fastcall KfAcquireSpinLock, ecx
  mov ecx, pIrql
  mov [ecx], al
  ret
CsqAcquireLock endp

CsqReleaseLock proc uses ecx edx pCsqInfo:PIO_CSQ, Irql:KIRQL
  local pdx:PTR DevExt
  
  ; CONTAINING_RECORD 
  mov eax, pCsqInfo
  sub eax, OurDeviceExtension.stCsq
  mov pdx, eax

  mov dl, Irql
  mov eax, pdx
  lea ecx, (OurDeviceExtension PTR [eax]).stLock
  .if dl == DISPATCH_LEVEL
    fastcall KefReleaseSpinLockFromDpcLevel, ecx
    push eax
    invoke DbgPrint, $CTA0("CsqReleaseLock at DPC level\n")
    pop eax
  .else
    and edx, 0FFh
    fastcall KfReleaseSpinLock, ecx, edx
    push eax
    invoke DbgPrint, $CTA0("CsqReleaseLock at Passive level\n")
    pop eax
  .endif
  ret
CsqReleaseLock endp

OnTimer proc uses ebx pDpc:PKDPC, pContext:PVOID, pArg1:PVOID, PArg2:PVOID
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
    mov bl, (_IRP PTR [eax]).Cancel

    .if bl != TRUE
      mov (_IRP PTR [eax]).IoStatus.Status, STATUS_SUCCESS
      and (_IRP PTR [eax]).IoStatus.Information, 0
      fastcall IofCompleteRequest, eax, IO_NO_INCREMENT
      mov eax, STATUS_SUCCESS
      invoke DbgPrint, $CTA0("Complete Irp")
    .else
      mov (_IRP PTR [eax]).CancelRoutine, NULL
      mov (_IRP PTR [eax]).IoStatus.Status, STATUS_CANCELLED
      and (_IRP PTR [eax]).IoStatus.Information, 0
      fastcall IofCompleteRequest, eax, IO_NO_INCREMENT
      mov eax, STATUS_CANCELLED
      invoke DbgPrint, $CTA0("Cancel Irp")
    .endif
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

IrpIOCTL proc uses ebx pOurDevice:PDEVICE_OBJECT, pIrp:PIRP
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
    lea ebx, (OurDeviceExtension PTR [ebx]).stCsq
    invoke IoCsqInsertIrp, ebx, pIrp, NULL
    mov eax, STATUS_PENDING
    ret
  .elseif eax == IOCTL_PROCESS
    invoke DbgPrint, offset MSG_PROCESS
    or stTimePeriod.HighPart, -1
    mov stTimePeriod.LowPart, -10000000
    mov ebx, pdx
    invoke KeSetTimerEx, addr (OurDeviceExtension PTR [ebx]).stTime, stTimePeriod.LowPart, stTimePeriod.HighPart, 1000, addr (OurDeviceExtension PTR [ebx]).stDPC
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
    lea eax, (OurDeviceExtension PTR [eax]).stLock
    invoke KeInitializeSpinLock, eax

    mov eax, pOurDevice
    mov eax, (DEVICE_OBJECT PTR [eax]).DeviceExtension
    invoke KeInitializeTimer, addr (OurDeviceExtension ptr [eax]).stTime

    mov eax, pOurDevice
    mov eax, (DEVICE_OBJECT PTR [eax]).DeviceExtension
    invoke KeInitializeDpc, addr (OurDeviceExtension ptr [eax]).stDPC, offset OnTimer, pOurDevice

    mov eax, pOurDevice
    mov eax, (DEVICE_OBJECT PTR [eax]).DeviceExtension
    lea eax, (OurDeviceExtension PTR [eax]).stCsq
    invoke IoCsqInitialize, eax, offset CsqInsertIrp, offset CsqRemoveIrp, offset CsqPeekNextIrp, offset CsqAcquireLock, offset CsqReleaseLock, offset CsqCompleteCanceledIrp
    invoke IoCreateSymbolicLink, addr szSymName, addr suDevName
  .endif
  ret
DriverEntry endp
end DriverEntry
.end
