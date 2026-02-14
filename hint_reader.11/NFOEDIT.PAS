unit nfoedit;

{ LANG TEXT RANGE: 800-804 }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls,Main;

type
  TInfoEdit = class(TForm)
    Image1: TImage;
    Label1: TLabel;
    Memo1: TMemo;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Label2: TLabel;
    Edit1: TEdit;
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
  InfoEdit: TInfoEdit;

implementation

{$R *.DFM}

function TInfoEdit.MakeNew;
Var spTmp : TStringsPack;
begin
  InfoEdit.Memo1.Lines.Clear;
  InfoEdit.Edit1.Text := '';
  InfoEdit.ShowModal;
  spTmp := TStringsPack.Create;
  if IsValid then begin
    spTmp.sSimple := InfoEdit.Edit1.Text;
    spTmp.sComplex.Assign(InfoEdit.Memo1.Lines);
  end;  
  MakeNew := spTmp;
end;

procedure TInfoEdit.BitBtn1Click(Sender: TObject);
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

procedure TInfoEdit.BitBtn2Click(Sender: TObject);
begin
  IsValid := False;
  Close;
end;

procedure TInfoEdit.EditEntry(Var OldPack : TStringsPack);
Var spTmp : TStringsPack;
begin
  InfoEdit.Edit1.Text := OldPack.sSimple;
  InfoEdit.Memo1.Lines.Assign(OldPack.sComplex);
  InfoEdit.ShowModal;
  if IsValid then begin
    OldPack.sSimple := InfoEdit.Edit1.Text;
    OldPack.sComplex.Assign(InfoEdit.Memo1.Lines);
  end;
end;

procedure TInfoEdit.SetLanguage( HL : THandle );
Var Buffer : array[0..254] of char;
begin
  LoadString(HL,800,Buffer,sizeof(Buffer));
  InfoEdit.Caption := StrPas(Buffer);
  LoadString(HL,801,Buffer,sizeof(Buffer));
  InfoEdit.Label2.Caption := StrPas(Buffer);
  LoadString(HL,802,Buffer,sizeof(Buffer));
  InfoEdit.Label1.Caption := StrPas(Buffer);
  LoadString(HL,803,Buffer,sizeof(Buffer));
  BitBtn1.Caption := StrPas(Buffer);
  LoadString(HL,804,Buffer,sizeof(Buffer));
  BitBtn2.Caption := StrPas(Buffer);
end;


procedure TInfoEdit.FormActivate(Sender: TObject);
begin
  InfoEdit.Edit1.SetFocus;
end;

procedure TInfoEdit.FormResize(Sender: TObject);
begin
  if ClientWidth < 427 then ClientWidth := 427;
  if ClientHeight < 154 then ClientHeight := 154;
  Image1.Top := ClientHeight-5-Image1.Height;
  BitBtn1.Top := ClientHeight-10-BitBtn1.Height;
  BitBtn1.Left := ClientWidth-15-BitBtn2.Width-40-BitBtn1.Width;
  BitBtn2.Top := ClientHeight-10-BitBtn2.Height;
  BitBtn2.Left := ClientWidth-15-BitBtn2.Width;
  Edit1.Width := ClientWidth-32;
  Memo1.Width := ClientWidth -32;
  Memo1.Height := ClientHeight-Memo1.Top-10-Image1.Height;
end;

end.
