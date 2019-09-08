program main;

{$APPTYPE CONSOLE}

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  DIALOGS;

const
  METHOD_BUFFERED = 0;
  METHOD_IN_DIRECT = 1;
  METHOD_OUT_DIRECT = 2;
  METHOD_NEITHER = 3;
  FILE_ANY_ACCESS = 0;
  FILE_DEVICE_UNKNOWN = $22;

var
  fd: DWORD;
  ret: DWORD;
  len: DWORD;
  buf: array[0..255] of char;
  set_code: DWORD;
  get_code: DWORD;

begin
  fd:= CreateFile('\\.\MyDriver', GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, Nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if (fd <> INVALID_HANDLE_VALUE) then
  begin
    StrCopy(buf, 'I am error');
    len:= strlen(buf)+1;
    set_code:= (FILE_DEVICE_UNKNOWN shl 16) or (FILE_ANY_ACCESS shl 14) or ($800 shl 2) or (METHOD_NEITHER);
    get_code:= (FILE_DEVICE_UNKNOWN shl 16) or (FILE_ANY_ACCESS shl 14) or ($801 shl 2) or (METHOD_NEITHER);
    DeviceIoControl(fd, set_code, @buf, len, Nil, 0, ret, Nil);
    WriteLn(Output, Format('SET: %s, %d', [buf, len]));

    FillChar(buf, sizeof(buf), #0);
    DeviceIoControl(fd, get_code, Nil, 0, @buf, len, ret, Nil);
    WriteLn(Output, Format('GET: %s, %d', [buf, ret]));
    
    CloseHandle(fd);
  end else
  begin
    WriteLn(Output, 'failed to open mydriver');
  end;
end.
