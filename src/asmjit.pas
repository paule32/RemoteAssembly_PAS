// ----------------------------------------------------------------
// This file is part of Remote-Assembly-Engine RTL.
//
// (c) Copyright 2022 Jens Kallup - <paule32.jk@gmail.com>
// all rights reserved.
//
// only for non-profit, and/or education usage !!!
// ----------------------------------------------------------------
{$mode delphi}{$H+}
program asmJIT;

uses
  App,      // TApplication
  Objects,  // Window area (TRect)
  Drivers,  // Hotkey
  Views,    // Event (cmQuit)
  Menus,    // Statusbar
  MsgBox,   // MessageBox
  
  Classes,
  SysUtils,
  Dialogs,
  DosUtils,
  
  remoteAssembly;

type
  TAsmJIT_Desktop = object(TApplication)
    procedure InitStatusLine; virtual;   // status line
    procedure InitMenuBar; virtual;      // menu
  end;

// ----------------------------------------------------------------
// the new methode for the statusline
// R.A := left-top
// R.B := right-bottom
// ----------------------------------------------------------------
procedure TAsmJIT_Desktop.InitStatusLine;
var
  R: Objects.TRect;
  P0        : PStatusDef;   // pointer to full item
  P1, P2, P3: PStatusItem;  // pointer to hotkey's
begin
  GetExtent(R);        // get size/position of application
  R.A.Y := R.B.Y - 1;  // place statusbar on last line
  
  P3 := NewStatusKey('~F1~ Help' ,               kbF1  , cmHelp, nil);
  P2 := NewStatusKey('~F10~ Menu',               kbF10 , cmMenu, P3 );
  P1 := NewStatusKey('~Alt+X~ Exit Application', kbAltX, cmQuit, P2 );
  P0 := NewStatusDef(0, $FFFF, P1, nil);
  
  StatusLine := New(PStatusLine,Init(R, P0));
end;

// ----------------------------------------------------------------
// the new methode for the menuline
// R.A := left-top
// R.B := right-bottom
// ----------------------------------------------------------------
procedure TAsmJIT_Desktop.InitMenuBar;
var
  R: Objects.TRect;
begin
  GetExtent(R);
  R.B.Y := R.A.Y + 1;   // menu position
  
  MenuBar := New(PMenuBar,
  Init(R, NewMenu(
          NewSubMenu('~F~ile', hcNoContext, NewMenu(
             NewItem('~Alt+X~', 'Alt+X',
             kbAltX, cmQuit, hcNoContext,
             nil)),
          nil))));
end;

var
  debugApp : TAsmJIT_Desktop;
  
// ----------------------------------------------------------------
// Entry point for the application
// ----------------------------------------------------------------
begin
  try
    try
      // remote assembly stuff
      JitRunTime   := TASMJIT_RunTime  .Create;
      JitAssembler := TASMJIT_Assembler.Create(JitRunTime);
      
      // TUI init stuff
      debugApp.Init;  // init
      
      MessageBox('Hallo', nil, mfOkButton);
 
      debugApp.Run ;  // processed
      debugApp.Done;  // release
    except
      on E: Exception do
      begin
        ShowMessage('Exception:' + #13#10 +
        E.Message);
      end;
    end;
  finally
    JitAssembler.Free;
    JitRuntime  .Free;
  end;
end.
