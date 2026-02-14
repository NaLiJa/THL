unit CompWnd;

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

end.
