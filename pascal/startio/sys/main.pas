unit main;

interface
  uses 
    DDDK;

  const 
    DEV_NAME = '\Device\MyDriver';
    SYM_NAME = '\DosDevices\MyDriver';
    
  function _DriverEntry(pOurDriver:PDriverObject; pOurRegistry:PUnicodeString):NTSTATUS; stdcall;

implementation
var
  szBuf: array[0..255] of char;
  
function IrpOpen(pOurDevice:PDeviceObject; pIrp:PIrp):NTSTATUS; stdcall;
begin
  DbgPrint('IRP_MJ_CREATE', []);
  Result:= STATUS_SUCCESS;
  pIrp^.IoStatus.Information:= 0;
  pIrp^.IoStatus.Status:= Result;
  IoCompleteRequest(pIrp, IO_NO_INCREMENT);
end;

function IrpRead(pOurDevice:PDeviceObject; pIrp:PIrp):NTSTATUS; stdcall;
begin
  DbgPrint('IrpFile, IRP_MJ_READ', []);
  
  IoMarkIrpPending(pIrp);
  IoStartPacket(pOurDevice, pIrp, Nil, Nil);
  Result:= STATUS_PENDING;
end;

function IrpWrite(pOurDevice:PDeviceObject; pIrp:PIrp):NTSTATUS; stdcall;
begin
  DbgPrint('IrpFile, IRP_MJ_WRITE', []);
  
  IoMarkIrpPending(pIrp);
  IoStartPacket(pOurDevice, pIrp, Nil, Nil);
  Result:= STATUS_PENDING;
end;

function IrpClose(pOurDevice:PDeviceObject; pIrp:PIrp):NTSTATUS; stdcall;
begin
  DbgPrint('IRP_MJ_CLOSE', []);
  Result:= STATUS_SUCCESS;
  pIrp^.IoStatus.Information:= 0;
  pIrp^.IoStatus.Status:= Result;
  IoCompleteRequest(pIrp, IO_NO_INCREMENT);
end;

function StartIo(pOurDevice:PDeviceObject; pIrp:PIrp):NTSTATUS; stdcall;
var
  len: ULONG;
  psk: PIoStackLocation;
  
begin
  len:= 0;
  psk:= IoGetCurrentIrpStackLocation(pIrp);
  if psk^.MajorFunction = IRP_MJ_WRITE then
  begin
    DbgPrint('StartIo, IRP_MJ_WRITE', []);
    len:= psk.Parameters.Write.Length;
    memcpy(@szBuf[0], pIrp^.AssociatedIrp.SystemBuffer, len);
    DbgPrint('Buffer: %s, Length: %d', [szBuf, len]);
  end
  else if psk^.MajorFunction = IRP_MJ_READ then
  begin
    DbgPrint('StartIo, IRP_MJ_READ', []);
    len:= strlen(@szBuf[0])+1;
    memcpy(pIrp^.AssociatedIrp.SystemBuffer, @szBuf[0], len);
  end;
  
  Result:= STATUS_SUCCESS;
  pIrp^.IoStatus.Information:= len;
  pIrp^.IoStatus.Status:= Result;
  IoCompleteRequest(pIrp, IO_NO_INCREMENT);
  IoStartNextPacket(pOurDevice, FALSE);
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
    pOurDriver^.MajorFunction[IRP_MJ_READ]  := @IrpRead;
    pOurDriver^.MajorFunction[IRP_MJ_WRITE] := @IrpWrite;
    pOurDriver^.MajorFunction[IRP_MJ_CLOSE] := @IrpClose;
    pOurDriver^.DriverStartIo := @StartIo;
    pOurDriver^.DriverUnload := @Unload;
    pOurDevice^.Flags:= pOurDevice^.Flags or DO_BUFFERED_IO;
    pOurDevice^.Flags:= pOurDevice^.Flags and not DO_DEVICE_INITIALIZING;
    Result:= IoCreateSymbolicLink(@szSymName, @suDevName);
  end;
end;
end.
