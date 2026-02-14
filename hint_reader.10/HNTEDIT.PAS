unit hntedit;

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

end.
