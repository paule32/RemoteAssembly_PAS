// ----------------------------------------------------------------
// This file is part of Remote-Assembly-Engine RTL.
//
// (c) Copyright 2022 Jens Kallup - <paule32.jk@gmail.com>
// all rights reserved.
//
// only for non-profit, and/or education usage !!!
// ----------------------------------------------------------------
unit DosUtils;

interface
uses Windows;

procedure ShowMessage(AString: String);

implementation
{$IFDEF FPC}
// ----------------------------------------------------------------
// display information's for the user.
// ----------------------------------------------------------------
procedure ShowMessage(AString: String);
begin
  Windows.MessageBox(0,PChar(AString),PChar('Info'),0);
end;
{$ENDIF}

end.
