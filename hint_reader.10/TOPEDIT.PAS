unit topedit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons,Main, ExtCtrls;

type
  TTopicEdit = class(TForm)
    Edit1: TEdit;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Image1: TImage;
    Label1: TLabel;
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
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
  TopicEdit: TTopicEdit;

implementation

{$R *.DFM}

procedure TTopicEdit.BitBtn2Click(Sender: TObject);
begin
  IsValid := False;
  Close;
end;

procedure TTopicEdit.BitBtn1Click(Sender: TObject);
begin
  IsValid := True;
  Close;
end;

function TTopicEdit.MakeNew;
Var spTmp : TStringsPack;
begin
  TopicEdit.Edit1.Text := '';
  TopicEdit.ShowModal;
  spTmp := TStringsPack.Create;
  if IsValid then begin
    spTmp.sSimple := TopicEdit.Edit1.Text;
    MakeNew := spTmp;
  end
  else begin
    spTmp.sSimple := '';
    MakeNew := spTmp;
  end;
end;

procedure TTopicEdit.EditEntry(Var OldPack : TStringsPack);
Var spTmp : TStringsPack;
begin
  TopicEdit.Edit1.Text := OldPack.sSimple;
  TopicEdit.ShowModal;
  if IsValid then
    OldPack.sSimple := TopicEdit.Edit1.Text;
end;

procedure TTopicEdit.SetLanguage( HL : Thandle );
Var Buffer : array[0..254] of char;
begin
  LoadString(HL,650,Buffer,sizeof(Buffer));
    TopicEdit.Caption := StrPas(Buffer);
  LoadString(HL,651,Buffer,sizeof(Buffer));
    TopicEdit.BitBtn2.Caption := StrPas(Buffer);
  LoadString(HL,652,Buffer,sizeof(Buffer));
    TopicEdit.BitBtn1.Caption := StrPas(Buffer);
end;

end.
