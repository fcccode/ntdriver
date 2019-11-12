#include <wdm.h>

#define IOCTL_QUEUE   CTL_CODE(FILE_DEVICE_UNKNOWN, 0x800, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_PROCESS CTL_CODE(FILE_DEVICE_UNKNOWN, 0x801, METHOD_BUFFERED, FILE_ANY_ACCESS)

#define DEV_NAME L"\\Device\\MyDriver"
#define SYM_NAME L"\\DosDevices\\MyDriver"

KDPC stDPC={0};
IO_CSQ stCsq={0};
KTIMER stTime={0};
KSPIN_LOCK stLock={0};
LIST_ENTRY stQueue={0};

VOID CsqInsertIrp(struct _IO_CSQ *pCsq, PIRP pIrp)
{
  DbgPrint("CsqInsertIrp");
  InsertTailList(&stQueue, &pIrp->Tail.Overlay.ListEntry);
}

VOID CsqRemoveIrp(PIO_CSQ pCsq, PIRP pIrp)
{
  UNREFERENCED_PARAMETER(pCsq);
  DbgPrint("CsqRemoveIrp");
  RemoveEntryList(&pIrp->Tail.Overlay.ListEntry);
}

VOID CsqCompleteCanceledIrp(PIO_CSQ pCsq, PIRP pIrp)
{
  UNREFERENCED_PARAMETER(pCsq);
  DbgPrint("CsqCompleteCanceledIrp");
  pIrp->IoStatus.Status = STATUS_CANCELLED;
  pIrp->IoStatus.Information = 0;
  IoCompleteRequest(pIrp, IO_NO_INCREMENT);
}

PIRP CsqPeekNextIrp(PIO_CSQ pCsq, PIRP pIrp, PVOID PeekContext)
{
  PIRP pNextIrp=NULL;
  PLIST_ENTRY pList=NULL;
  PLIST_ENTRY pNext=NULL;
  PIO_STACK_LOCATION psk=NULL;
  
  pList = &stQueue;
  if(pIrp == NULL){
    pNext = pList->Flink;
  }
  else{
    pNext = pIrp->Tail.Overlay.ListEntry.Flink;
  }

  while(pNext != pList){
    pNextIrp = CONTAINING_RECORD(pNext, IRP, Tail.Overlay.ListEntry);
    psk = IoGetCurrentIrpStackLocation(pNextIrp);
    if(PeekContext){
      if(psk->FileObject == (PFILE_OBJECT)PeekContext){
        break;
      }
    }
    else{
      break;
    }
    pNextIrp = NULL;
    pNext = pNext->Flink;
  }
  return pNextIrp;
}

VOID CsqAcquireLock(PIO_CSQ pCsq, KIRQL *pIrql)
{
  DbgPrint("CsqAcquireLock");
  KeAcquireSpinLock(&stLock, pIrql);
}

VOID CsqReleaseLock(PIO_CSQ pCsq, KIRQL pIrql)
{
  if(pIrql == DISPATCH_LEVEL){
    KeReleaseSpinLockFromDpcLevel(&stLock);
    DbgPrint("CsqReleaseLock at DPC level");
  }
  else{
    KeReleaseSpinLock(&stLock, pIrql);
    DbgPrint("CsqReleaseLock at Passive level");
  }
}

VOID OnTimer(struct _KDPC *Dpc, PVOID DeferredContext, PVOID SystemArgument1, PVOID SystemArgument2)
{
  PIRP pIrp;
  PLIST_ENTRY plist;
  if(IsListEmpty(&stQueue) == TRUE){
    KeCancelTimer(&stTime);
    DbgPrint("Finish");
  }
  else{
    plist = RemoveHeadList(&stQueue);
    pIrp = CONTAINING_RECORD(plist, IRP, Tail.Overlay.ListEntry);
    if(pIrp->Cancel != TRUE){
      pIrp->IoStatus.Status = STATUS_SUCCESS;
      pIrp->IoStatus.Information = 0;
      IoCompleteRequest(pIrp, IO_NO_INCREMENT);
      DbgPrint("Complete Irp");
    }
    else{
      pIrp->CancelRoutine = NULL;
      pIrp->IoStatus.Status = STATUS_CANCELLED;
      pIrp->IoStatus.Information = 0;
      IoCompleteRequest(pIrp, IO_NO_INCREMENT);
      DbgPrint("Cancel Irp");
    }
  }
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
  LARGE_INTEGER stTimePeriod;
  PIO_STACK_LOCATION psk = IoGetCurrentIrpStackLocation(pIrp);

  switch(psk->Parameters.DeviceIoControl.IoControlCode){
  case IOCTL_QUEUE:
    DbgPrint("IOCTL_QUEUE");
    IoCsqInsertIrp(&stCsq, pIrp, NULL);
    return STATUS_PENDING;
  case IOCTL_PROCESS:
    DbgPrint("IOCTL_PROCESS");
    stTimePeriod.HighPart|= -1;
    stTimePeriod.LowPart = -1000000;
    KeSetTimerEx(&stTime, stTimePeriod, 1000, &stDPC);
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
  InitializeListHead(&stQueue);
  KeInitializeSpinLock(&stLock);
  KeInitializeTimer(&stTime);
  KeInitializeDpc(&stDPC, OnTimer, pOurDevice);
  IoCsqInitialize(&stCsq, CsqInsertIrp, CsqRemoveIrp, CsqPeekNextIrp, CsqAcquireLock, CsqReleaseLock, CsqCompleteCanceledIrp);
  IoCreateSymbolicLink(&usSymboName, &usDeviceName);
  pOurDevice->Flags&= ~DO_DEVICE_INITIALIZING;
  pOurDevice->Flags|= DO_BUFFERED_IO;
  return STATUS_SUCCESS;
}
