#include <wdm.h>

#define IOCTL_START CTL_CODE(FILE_DEVICE_UNKNOWN, 0x800, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_STOP  CTL_CODE(FILE_DEVICE_UNKNOWN, 0x801, METHOD_BUFFERED, FILE_ANY_ACCESS)

#define DEV_NAME L"\\Device\\MyDriver"
#define SYM_NAME L"\\DosDevices\\MyDriver"


ULONG dwTimerCnt=0;
KDPC stTimerDPC={0};
KTIMER stTimerObj={0};

VOID OnTimer(struct _KDPC *Dpc, PVOID DeferredContext, PVOID SystemArgument1, PVOID SystemArgument2)
{
  dwTimerCnt+= 1;
  DbgPrint("DpcTimer: %d\n", dwTimerCnt);
}

void Unload(PDRIVER_OBJECT pOurDriver)
{
  UNICODE_STRING usSymboName;
             
  RtlInitUnicodeString(&usSymboName, L"\\DosDevices\\MyDriver");
  IoDeleteSymbolicLink(&usSymboName);
  IoDeleteDevice(pOurDriver->DeviceObject);
}

NTSTATUS IrpIOCTL(PDEVICE_OBJECT pOurDevice, PIRP pIrp)
{
  LARGE_INTEGER stTimeCnt;
  PIO_STACK_LOCATION psk = IoGetCurrentIrpStackLocation(pIrp);

  switch(psk->Parameters.DeviceIoControl.IoControlCode){
  case IOCTL_START:
    DbgPrint("IOCTL_START");
    dwTimerCnt = 0;
    stTimeCnt.HighPart|= -1;
    stTimeCnt.LowPart = -10000000;
    KeSetTimerEx(&stTimerObj, stTimeCnt, 1000, &stTimerDPC);
    break;
  case IOCTL_STOP:
    DbgPrint("IOCTL_STOP");
    KeCancelTimer(&stTimerObj);
    break;
  }
  pIrp->IoStatus.Information = 0;
  pIrp->IoStatus.Status = STATUS_SUCCESS;
  IoCompleteRequest(pIrp, IO_NO_INCREMENT);
  return STATUS_SUCCESS;
}

NTSTATUS IrpFile(PDEVICE_OBJECT pOurDevice, PIRP pIrp)
{
  PIO_STACK_LOCATION psk = IoGetCurrentIrpStackLocation(pIrp);

  switch(psk->MajorFunction){
  case IRP_MJ_CREATE:
    DbgPrint("IRP_MJ_CREATE");
    break;
  case IRP_MJ_CLOSE:
    DbgPrint("IRP_MJ_CLOSE");
    break;
  }
  IoCompleteRequest(pIrp, IO_NO_INCREMENT);
  return STATUS_SUCCESS;
}

NTSTATUS DriverEntry(PDRIVER_OBJECT pOurDriver, PUNICODE_STRING pOurRegistry)
{
  PDEVICE_OBJECT pOurDevice=NULL;
  UNICODE_STRING usDeviceName;
  UNICODE_STRING usSymboName;
        
  pOurDriver->MajorFunction[IRP_MJ_CREATE] =
  pOurDriver->MajorFunction[IRP_MJ_CLOSE] = IrpFile;
  pOurDriver->MajorFunction[IRP_MJ_DEVICE_CONTROL] = IrpIOCTL;
  pOurDriver->DriverUnload = Unload;
          
  RtlInitUnicodeString(&usDeviceName, L"\\Device\\MyDriver");
  IoCreateDevice(pOurDriver, 0, &usDeviceName, FILE_DEVICE_UNKNOWN, 0, FALSE, &pOurDevice);
  RtlInitUnicodeString(&usSymboName, L"\\DosDevices\\MyDriver");
  KeInitializeTimer(&stTimerObj);
  KeInitializeDpc(&stTimerDPC, OnTimer, pOurDevice);
  IoCreateSymbolicLink(&usSymboName, &usDeviceName);
  pOurDevice->Flags&= ~DO_DEVICE_INITIALIZING;
  pOurDevice->Flags|= DO_BUFFERED_IO;
  return STATUS_SUCCESS;
}
