unit hntedit;

{ LANG TEXT RANGE: 600-602 }
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons,Main, ExtCtrls;

type
  THintEdit = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Memo1: TMemo;
    Image1: TImage;
    LabelX: TLabel;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    IsValid : Boolean;
    { Private-Deklarationen }
  public
    function MakeNew:TStringsPack;
    procedure EditEntry(Var OldPack : TStringsPack );
    procedure SetLanguage( HL : THandle );
    { Public-Deklarationen }
  end;

var
  HintEdit: THintEdit;

implementation

{$R *.DFM}

function THintEdit.MakeNew;
Var spTmp : TStringsPack;
begin
  HintEdit.Memo1.Lines.Clear;
  HintEdit.ShowModal;
  spTmp := TStringsPack.Create;
  if IsValid then
    spTmp.sComplex.Assign(HintEdit.Memo1.Lines);
  MakeNew := spTmp;
end;

procedure THintEdit.BitBtn1Click(Sender: TObject);
begin
  if (Memo1.Lines.Text = '') then begin
    IsValid := False;
    Close;
  end
  else begin
    IsValid := True;
    Close;
  end
end;

procedure THintEdit.BitBtn2Click(Sender: TObject);
begin
  IsValid := False;
  Close;
end;

procedure THintEdit.EditEntry(Var OldPack : TStringsPack);
Var spTmp : TStringsPack;
begin
  HintEdit.Memo1.Lines.Assign(OldPack.sComplex);
  HintEdit.ShowModal;
  if IsValid then begin
    OldPack.sComplex.Assign(HintEdit.Memo1.Lines);
  end;
end;

procedure THintEdit.SetLanguage( HL : THandle );
Var Buffer : array[0..254] of char;
begin
  LoadString(HL,600,Buffer,sizeof(Buffer));
  HintEdit.Caption := StrPas(Buffer);
  LoadString(HL,601,Buffer,sizeof(Buffer));
  HintEdit.BitBtn2.Caption := StrPas(Buffer);
  LoadString(HL,602,Buffer,sizeof(Buffer));
  HintEdit.BitBtn1.Caption := StrPas(Buffer);
end;

procedure THintEdit.FormActivate(Sender: TObject);
begin
   Memo1.SetFocus;
end;

procedure THintEdit.FormResize(Sender: TObject);
begin
  if ClientWidth < 400 then ClientWidth := 400;
  if ClientHeight < 114 then ClientHeight := 114;
  Image1.Top := ClientHeight-5-Image1.Height;
  BitBtn1.Top := ClientHeight-10-BitBtn1.Height;
  BitBtn1.Left := ClientWidth-13-BitBtn2.Width-40-BitBtn1.Width;
  BitBtn2.Top := ClientHeight-10-BitBtn2.Height;
  BitBtn2.Left := ClientWidth-13-BitBtn2.Width;
  Memo1.Width := ClientWidth -32;
  Memo1.Height := ClientHeight-Memo1.Top-20-BitBtn1.Height;
end;

end.
