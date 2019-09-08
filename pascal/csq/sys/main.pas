unit main;

interface
  uses 
    DDDK;
    
  const 
    DEV_NAME = '\Device\MyDriver';
    SYM_NAME = '\DosDevices\MyDriver';
    IOCTL_QUEUE = $222000; // CTL_CODE(FILE_DEVICE_UNKNOWN, 0x800, METHOD_BUFFERED, FILE_ANY_ACCESS)
    IOCTL_PROCESS = $222004; // CTL_CODE(FILE_DEVICE_UNKNOWN, 0x801, METHOD_BUFFERED, FILE_ANY_ACCESS)
    
  function _DriverEntry(pOurDriver:PDriverObject; pOurRegistry:PUnicodeString):NTSTATUS; stdcall;

implementation
var 
  dpc: TKDpc;
  obj: KTIMER;
  csq: IO_CSQ;
  lock: KSPIN_LOCK;
  queue: LIST_ENTRY;

procedure CsqInsertIrp(pCsqInfo:PIO_CSQ; pIrp:PIRP); stdcall;
begin
  DbgPrint('CsqInsertIrp', []);
  InsertTailList(@queue, @pIrp^.Tail.Overlay.s1.ListEntry);
end;

procedure CsqRemoveIrp(pCsqInfo:PIO_CSQ; pIrp:PIRP); stdcall;
begin
  DbgPrint('CsqRemoveIrp', []);
  RemoveEntryList(@pIrp^.Tail.Overlay.s1.ListEntry);
end;

function CsqPeekNextIrp(Csq:PIO_CSQ; Irp:PIRP; PeekContext:Pointer):PIRP; stdcall;
begin
  DbgPrint('CsqPeekNextIrp', []);
  Result:= Nil;
end;

procedure CsqAcquireLock(Csq:PIO_CSQ; Irql:PKIRQL); stdcall;
begin
  DbgPrint('CsqAcquireLock', []);
  KiAcquireSpinLock(@lock);
end;

procedure CsqReleaseLock(Csq:PIO_CSQ; Irql:KIRQL); stdcall;
begin
  if Irql = DISPATCH_LEVEL then
  begin
    KefReleaseSpinLockFromDpcLevel(@lock);
    DbgPrint('CsqReleaseLock at DPC level', []);
  end else
  begin
    KiReleaseSpinLock(@lock);
    DbgPrint('CsqReleaseLock at Passive level', []);
  end;
end;

procedure CsqCompleteCanceledIrp(Csq:PIO_CSQ; pIrp:PIRP); stdcall;
begin
  DbgPrint('CsqCompleteCanceledIrp', []);
  pIrp^.IoStatus.Status:= STATUS_CANCELLED;
  pIrp^.IoStatus.Information:= 0;
  IoCompleteRequest(pIrp, IO_NO_INCREMENT);
end;

procedure OnTimer(Dpc:KDPC; DeferredContext:Pointer; SystemArgument1:Pointer; SystemArgument2:Pointer); stdcall;
var
  irp: PIRP;
  plist: PLIST_ENTRY;
  
begin
  if IsListEmpty(@queue) = True then
  begin
    KeCancelTimer(@obj);
    DbgPrint('Finish', []);
  end
  else
  begin
    plist:= RemoveHeadList(@queue);
    
    // CONTAINING_RECORD(IRP.Tail.Overlay.ListEntry)
    irp:= Pointer(Integer(plist) - 88);
    if irp^.Cancel = False then
    begin
      irp^.IoStatus.Status:= STATUS_SUCCESS;
      irp^.IoStatus.Information:= 0;
      IoCompleteRequest(irp, IO_NO_INCREMENT);
      DbgPrint('Complete Irp', []);
    end
    else
    begin
      irp^.CancelRoutine:= Nil;
      irp^.IoStatus.Status:= STATUS_CANCELLED;
      irp^.IoStatus.Information:= 0;
      IoCompleteRequest(irp, IO_NO_INCREMENT);
      DbgPrint('Cancel Irp', []);
    end;
  end;
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
  IOCTL_QUEUE:begin
    DbgPrint('IOCTL_QUEUE', []);
    IoCsqInsertIrp(@csq, pIrp, Nil);
    Result:= STATUS_PENDING;
    exit
  end;
  IOCTL_PROCESS:begin
    DbgPrint('IOCTL_PROCESS', []);
    tt.HighPart:= tt.HighPart or -1;
    tt.LowPart:= ULONG(-10000000);
    KeSetTimerEx(@obj, tt.LowPart, tt.HighPart, 1000, @dpc);
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
    InitializeListHead(@queue);
    KeInitializeSpinLock(@lock);
    KeInitializeTimer(@obj);
    KeInitializeDpc(@dpc, OnTimer, pOurDevice);
    IoCsqInitialize(@csq, CsqInsertIrp, CsqRemoveIrp, CsqPeekNextIrp, CsqAcquireLock, CsqReleaseLock, CsqCompleteCanceledIrp);
    Result:= IoCreateSymbolicLink(@szSymName, @suDevName);
  end;
end;
end.
