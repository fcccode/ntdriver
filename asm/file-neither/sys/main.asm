.386p
.model flat, stdcall
option casemap:none

include c:\masm32\Macros\Strings.mac
include c:\masm32\include\w2k\ntstatus.inc
include c:\masm32\include\w2k\ntddk.inc
include c:\masm32\include\w2k\ntoskrnl.inc
include c:\masm32\include\w2k\ntddkbd.inc
include c:\masm32\include\wxp\wdm.inc
include c:\masm32\include\wxp\seh0.inc
includelib c:\masm32\lib\wxp\i386\ntoskrnl.lib
 
public DriverEntry
 
OurDeviceExtension struct
  pNextDevice PDEVICE_OBJECT ?
  szBuffer byte 255 dup(?)
OurDeviceExtension ends

.const
DEV_NAME word "\","D","e","v","i","c","e","\","M","y","D","r","i","v","e","r",0
SYM_NAME word "\","D","o","s","D","e","v","i","c","e","s","\","M","y","D","r","i","v","e","r",0

.code
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

IrpReadWrite proc uses ebx pOurDevice:PDEVICE_OBJECT, pIrp:PIRP
  local bReadable:dword
  local bWritable:dword
  local dwLen:dword
  local pBuf:dword
  local pdx:PTR OurDeviceExtension
  
  and dwLen, 0
  mov eax, pOurDevice
  push (DEVICE_OBJECT PTR [eax]).DeviceExtension
  pop pdx
  
  IoGetCurrentIrpStackLocation pIrp
  movzx eax, (IO_STACK_LOCATION PTR [eax]).MajorFunction
  .if eax == IRP_MJ_WRITE
    invoke DbgPrint, $CTA0("IRP_MJ_WRITE")
    
    IoGetCurrentIrpStackLocation pIrp
    push (IO_STACK_LOCATION PTR [eax]).Parameters.Write._Length
    pop dwLen
   
    mov eax, pIrp
    push (_IRP PTR [eax]).UserBuffer
    pop pBuf
    invoke DbgPrint, $CTA0("Address: 0x%x, Length: %d"), pBuf, dwLen
    
    mov bReadable, 0
    _try
      invoke ProbeForRead, pBuf, dwLen, 1
      mov eax, pdx
      mov ebx, pBuf
      invoke memcpy, addr (OurDeviceExtension PTR [eax]).szBuffer, ebx, dwLen
      mov bReadable, 1
    _finally
      .if bReadable == 0
        invoke DbgPrint, $CTA0("Failed to read from user buffer")
      .endif
  .elseif eax == IRP_MJ_READ
    invoke DbgPrint, $CTA0("IRP_MJ_READ")
   
    mov eax, pIrp
    push (_IRP PTR [eax]).UserBuffer
    pop pBuf

    mov bWritable, 0
    _try
      invoke ProbeForWrite, pBuf, dwLen, 1
      mov eax, pOurDevice
      push (DEVICE_OBJECT PTR [eax]).DeviceExtension
      pop pdx
    
      mov eax, pdx
      mov ebx, pBuf
      invoke strcpy, ebx, addr (OurDeviceExtension PTR [eax]).szBuffer
      
      mov eax, pdx
      invoke strlen, addr (OurDeviceExtension PTR [eax]).szBuffer
      inc eax
      push eax
      pop dwLen
    
      mov bWritable, 1
    _finally
      .if bWritable == 0
        invoke DbgPrint, $CTA0("Failed to write to user buffer")
      .endif
  .endif
  
  mov eax, pIrp
  push dwLen
  pop (_IRP PTR [eax]).IoStatus.Information
  mov (_IRP PTR [eax]).IoStatus.Status, STATUS_SUCCESS
  fastcall IofCompleteRequest, pIrp, IO_NO_INCREMENT
  mov eax, STATUS_SUCCESS
  ret
IrpReadWrite endp

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
  mov (DRIVER_OBJECT PTR [eax]).MajorFunction[IRP_MJ_WRITE  * (sizeof PVOID)], offset IrpReadWrite
  mov (DRIVER_OBJECT PTR [eax]).MajorFunction[IRP_MJ_READ   * (sizeof PVOID)], offset IrpReadWrite
  mov (DRIVER_OBJECT PTR [eax]).DriverUnload, offset Unload
      
  invoke RtlInitUnicodeString, addr suDevName, offset DEV_NAME
  invoke RtlInitUnicodeString, addr szSymName, offset SYM_NAME
  invoke IoCreateDevice, pOurDriver, sizeof OurDeviceExtension, addr suDevName, FILE_DEVICE_UNKNOWN, 0, FALSE, addr pOurDevice
  .if eax == STATUS_SUCCESS
    mov eax, pOurDevice
    and (DEVICE_OBJECT PTR [eax]).Flags, not DO_DEVICE_INITIALIZING
    invoke IoCreateSymbolicLink, addr szSymName, addr suDevName
  .endif
  ret
DriverEntry endp
end DriverEntry
.end
