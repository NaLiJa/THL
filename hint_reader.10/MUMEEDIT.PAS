unit mumeedit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Main, ExtCtrls;

type
  TMMEdit = class(TForm)
    MMdesc: TEdit;
    MMFile: TEdit;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    Label1: TLabel;
    Label2: TLabel;
    OpenMM: TOpenDialog;
    Image1: TImage;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
  private
    IsValid  : Boolean;
    Messages : string;
    { Private-Deklarationen }
  public
    function MakeNew:TStringsPack;
    procedure EditEntry(Var OldPack : TStringsPack );
    procedure SetLanguage( HL : THandle );
    { Public-Deklarationen }
  end;

var
  MMEdit: TMMEdit;

implementation

uses LDMsgDlg;
{$R *.DFM}

function TMMEdit.MakeNew;
Var spTmp : TStringsPack;
begin
  MMDesc.Text := '';
  MMFile.Text := '';
  MMEdit.ShowModal;
  spTmp := TStringsPack.Create;
  if IsValid then begin
    spTmp.sComplex.Add(MMDesc.Text);
    spTmp.sComplex.Add(MMFile.Text);
    MakeNew := spTmp;
  end
  else
    MakeNew := spTmp;
end;

procedure TMMEdit.EditEntry(Var OldPack : TStringsPack);
Var spTmp : TStringsPack;
begin
  MMDesc.Text := OldPack.sComplex.Strings[0];
  MMFile.Text := OldPack.sComplex.Strings[1];
  MMEdit.ShowModal;
  if IsValid then begin
    OldPack.sComplex.Clear;
    OldPack.sComplex.Add(MMEdit.MMDesc.Text);
    OldPack.sComplex.Add(MMEdit.MMFile.Text);
  end;
end;

procedure TMMEdit.SetLanguage( HL : THandle );
Var Buffer : array[0..254] of char;
begin
  LoadString(HL,200,Buffer,sizeof(Buffer));
  MMEdit.Caption := StrPas(Buffer);
  LoadString(HL,201,Buffer,sizeof(Buffer));
  MMEdit.BitBtn2.Caption := StrPas(Buffer);
  LoadString(HL,202,Buffer,sizeof(Buffer));
  MMEdit.BitBtn3.Caption := StrPas(Buffer);
  LoadString(HL,203,Buffer,sizeof(Buffer));
  MMEdit.Label1.Caption := StrPas(Buffer);
  LoadString(HL,204,Buffer,sizeof(Buffer));
  MMEdit.Label2.Caption := StrPas(Buffer);
  LoadString(HL,205,Buffer,sizeof(Buffer));
  Messages := StrPas(Buffer);
  LoadString(HL,206,Buffer,sizeof(Buffer));
  MMEdit.BitBtn1.Caption := StrPas(Buffer);
end;

procedure TMMEdit.BitBtn1Click(Sender: TObject);
begin
  if ((MMFile.Text <> '') And (MMDesc.Text <> '')) then begin
    IsValid := True;
    Close;
  end
  else
    LDMessageDlg(Messages,mtError,[mbOK],0);
end;

procedure TMMEdit.BitBtn2Click(Sender: TObject);
begin
  IsValid := False;
  Close;
end;

procedure TMMEdit.BitBtn3Click(Sender: TObject);
begin
  if OpenMM.Execute then
    MMFile.Text := OpenMM.Filename;
end;

end.
