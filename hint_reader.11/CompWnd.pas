unit CompWnd;

{ LANG TEXT RANGE : NONE }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TCmpWnd = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
    procedure SetCaption( CapLine, Infoline : string );
    procedure SetTextLine( NewLine : string );
  end;

var
  CmpWnd: TCmpWnd;

implementation

{$R *.DFM}

procedure TCmpWnd.SetTextLine( NewLine : string );
begin
  Label2.Caption := NewLine;
  Refresh;
end;

procedure TCmpWnd.SetCaption( CapLine,Infoline : string );
begin
  CmpWnd.Caption := CapLine;
  Label1.Caption := Infoline;
  Refresh;
end;

end.
