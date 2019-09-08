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

var
  fd: DWORD;
  ret: DWORD;
  len: DWORD;
  szBuf: array[0..255] of char;

begin
  fd:= CreateFile('\\.\MyDriver', GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, Nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if (fd <> INVALID_HANDLE_VALUE) then
  begin
    StrCopy(szBuf, 'I am error');
    len:= strlen(szBuf)+1;
    WriteLn(Output, Format('WR: %s, %d', [szBuf, len]));
    WriteFile(fd, szBuf, len, ret, Nil);
    ReadFile(fd, szBuf, len, ret, Nil);
    WriteLn(Output, Format('RD: %s, %d', [szBuf, ret]));
    CloseHandle(fd);
  end else
  begin
    WriteLn(Output, 'failed to open mydriver');
  end;
end.
