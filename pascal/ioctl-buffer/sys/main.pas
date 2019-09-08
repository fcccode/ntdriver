unit main;

interface
  uses 
    DDDK;
    
  const 
    DEV_NAME = '\Device\MyDriver';
    SYM_NAME = '\DosDevices\MyDriver';
    IOCTL_SET = $222000; // CTL_CODE(FILE_DEVICE_UNKNOWN, 0x800, METHOD_BUFFERED, FILE_ANY_ACCESS)
    IOCTL_GET = $222004; // CTL_CODE(FILE_DEVICE_UNKNOWN, 0x801, METHOD_BUFFERED, FILE_ANY_ACCESS)
    
  function _DriverEntry(pOurDriver:PDriverObject; pOurRegistry:PUnicodeString):NTSTATUS; stdcall;

implementation
var 
  szBuffer: array[0..255] of char;

function IrpOpen(pOurDevice:PDeviceObject; pIrp:PIrp):NTSTATUS; stdcall;
begin
  DbgPrint('IRP_MJ_CREATE', []);
  Result:= STATUS_SUCCESS;
  pIrp^.IoStatus.Information:= 0;
  pIrp^.IoStatus.Status:= Result;
  IoCompleteRequest(pIrp, IO_NO_INCREMENT);
end;

function IrpClose(pOurDevice:PDeviceObject; pIrp:PIrp):NTSTATUS; stdcall;
begin
  DbgPrint('IRP_MJ_CLOSE', []);
  Result:= STATUS_SUCCESS;
  pIrp^.IoStatus.Information:= 0;
  pIrp^.IoStatus.Status:= Result;
  IoCompleteRequest(pIrp, IO_NO_INCREMENT);
end;

function IrpIOCTL(pOurDevice:PDeviceObject; pIrp:PIrp):NTSTATUS; stdcall;
var
  len: ULONG;
  code: ULONG;
  psk: PIoStackLocation;

begin
  len:= 0;
  psk:= IoGetCurrentIrpStackLocation(pIrp);
  code:= psk^.Parameters.DeviceIoControl.IoControlCode;
  case code of 
  IOCTL_GET:begin
    DbgPrint('IOCTL_GET', []);
    len:= strlen(@szBuffer[0])+1;
    memcpy(pIrp^.AssociatedIrp.SystemBuffer, @szBuffer[0], len);
  end;
  IOCTL_SET:begin
    DbgPrint('IOCTL_SET', []);
    len:= psk^.Parameters.DeviceIoControl.InputBufferLength;
    memcpy(@szBuffer[0], pIrp^.AssociatedIrp.SystemBuffer, len);
    DbgPrint('Buffer: %s, Length: %d', [szBuffer, len]);
  end;
  end;
  
  Result:= STATUS_SUCCESS;
  pIrp^.IoStatus.Information:= len;
  pIrp^.IoStatus.Status:= Result;
  IoCompleteRequest(pIrp, IO_NO_INCREMENT);
end;

procedure Unload(pOurDriver:PDriverObject); stdcall;
var
  szSymName: TUnicodeString;

begin
  RtlInitUnicodeString(@szSymName, SYM_NAME);
  IoDeleteSymbolicLink(@szSymName);
  IoDeleteDevice(pOurDriver^.DeviceObject);
end;

function _DriverEntry(pOurDriver:PDriverObject; pOurRegistry:PUnicodeString):NTSTATUS; stdcall;
var
  suDevName: TUnicodeString;
  szSymName: TUnicodeString;
  pOurDevice: PDeviceObject;
  
begin
  RtlInitUnicodeString(@suDevName, DEV_NAME);
  RtlInitUnicodeString(@szSymName, SYM_NAME);
  Result:= IoCreateDevice(pOurDriver, 0, @suDevName, FILE_DEVICE_UNKNOWN, 0, FALSE, pOurDevice);

  if NT_SUCCESS(Result) then
  begin
    pOurDriver^.MajorFunction[IRP_MJ_CREATE]:= @IrpOpen;
    pOurDriver^.MajorFunction[IRP_MJ_CLOSE]  := @IrpClose;
    pOurDriver^.MajorFunction[IRP_MJ_DEVICE_CONTROL] := @IrpIOCTL;
    pOurDriver^.DriverUnload := @Unload;
    pOurDevice^.Flags:= pOurDevice^.Flags or DO_BUFFERED_IO;
    pOurDevice^.Flags:= pOurDevice^.Flags and not DO_DEVICE_INITIALIZING;
    Result:= IoCreateSymbolicLink(@szSymName, @suDevName);
  end;
end;
end.
