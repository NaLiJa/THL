unit hntwnd;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Main;

type
  THintWindow = class(TForm)
    BitBtn1: TBitBtn;
    HintMemo: TMemo;
    BitBtn2: TBitBtn;
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    procedure SetLanguage( HL : THandle );
    { Public-Deklarationen }
  end;

var
  HintWindow: THintWindow;

implementation

{$R *.DFM}

procedure THintWindow.BitBtn2Click(Sender: TObject);
begin
  Close;
  HintMemo.Color := HintMemo.Font.Color;
  BitBtn2.Enabled := False;
  HintMemo.Lines.Clear;
end;

procedure THintWindow.BitBtn1Click(Sender: TObject);
begin
  HintMemo.Color := clWindow;
  BitBtn2.Enabled := True;
end;

procedure THintWindow.SetLanguage( HL : THandle );
Var Buffer : array[0..254] of char;
begin
  LoadString(HL,400,Buffer,sizeof(Buffer));
    HintWindow.Caption := StrPas(Buffer);
  LoadString(HL,401,Buffer,sizeof(Buffer));
    BitBtn1.Caption := StrPas(Buffer);
  LoadString(HL,402,Buffer,sizeof(Buffer));
    BitBtn2.Caption := StrPas(Buffer);
end;

procedure THintWindow.FormCreate(Sender: TObject);
begin
  HintMemo.Color := HintMemo.Font.Color;
end;

end.
