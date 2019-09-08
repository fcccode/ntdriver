unit main;

interface
  uses 
    DDDK;
    
  const 
    DEV_NAME = '\Device\MyDriver';
    SYM_NAME = '\DosDevices\MyDriver';
    IOCTL_START = $222000; // CTL_CODE(FILE_DEVICE_UNKNOWN, 0x800, METHOD_BUFFERED, FILE_ANY_ACCESS)
    IOCTL_STOP = $222004; // CTL_CODE(FILE_DEVICE_UNKNOWN, 0x801, METHOD_BUFFERED, FILE_ANY_ACCESS)
    
  function _DriverEntry(pOurDriver:PDriverObject; pOurRegistry:PUnicodeString):NTSTATUS; stdcall;

implementation
var 
  cnt: ULONG;
  dpc: TKDpc;
  obj: KTIMER;

procedure OnTimer(Dpc:KDPC; DeferredContext:Pointer; SystemArgument1:Pointer; SystemArgument2:Pointer); stdcall;
begin
  cnt:= cnt + 1;
  DbgPrint('DpcTimer: %d', [cnt]);
end;

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
  code: ULONG;
  tt: LARGE_INTEGER;
  psk: PIoStackLocation;
  
begin
  psk:= IoGetCurrentIrpStackLocation(pIrp);
  code:= psk^.Parameters.DeviceIoControl.IoControlCode;
  case code of 
  IOCTL_START:begin
    DbgPrint('IOCTL_START', []);
    cnt:= 0;
    tt.HighPart:= tt.HighPart or -1;
    tt.LowPart:= ULONG(-10000000);
    KeSetTimerEx(@obj, tt.LowPart, tt.HighPart, 1000, @dpc);
  end;
  IOCTL_STOP:begin
    DbgPrint('IOCTL_STOP', []);
    KeCancelTimer(@obj);
  end;
  end;
  
  Result:= STATUS_SUCCESS;
  pIrp^.IoStatus.Information:= 0;
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
    KeInitializeTimer(@obj);
    KeInitializeDpc(@dpc, OnTimer, pOurDevice);
    Result:= IoCreateSymbolicLink(@szSymName, @suDevName);
  end;
end;
end.
