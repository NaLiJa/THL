unit MediaWnd;

{ LANG TEXT RANGE: 450 }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, MPlayer, ExtCtrls, Main;

type
  TMMWnd = class(TForm)
    MMFormImg: TImage;
    MediaPlayer1: TMediaPlayer;
    BitBtn1: TBitBtn;
    Label1: TLabel;
    MMCombo: TComboBox;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure MMComboChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
      MMLinks : TList;
      procedure FillComboBox;
    { Private-Deklarationen }
  public
    procedure SetLanguage( HL : THandle );
    procedure ShowForm( OwnerLinks : TList );
    { Public-Deklarationen }
  end;

var
  MMWnd: TMMWnd;

implementation

uses reader;

{$R *.DFM}

procedure TMMWnd.BitBtn1Click(Sender: TObject);
begin
  Close;
end;

procedure TMMWnd.SetLanguage( HL : THandle );
Var Buffer : array[0..254] of char;
begin
  LoadString(HL,450,Buffer,sizeof(Buffer));
  MMWnd.Caption := StrPas(Buffer);
end;

procedure TMMWnd.FormActivate(Sender: TObject);
begin
  WindowState := wsNormal;
end;

procedure TMMWnd.ShowForm( OwnerLinks : TList );
begin
  MMLinks := OwnerLinks;
  if WindowState <> wsNormal then
    WindowState := wsNormal;
  FillComboBox;
  Show;
end;

procedure TMMWnd.FillComboBox;
Var i       : Integer;
    OneNode : TNodeLink;
begin
  MMCombo.Items.Clear;
  if MMLinks.Count > 0 then begin
    for i:=0 to MMLinks.Count-1 do begin
      OneNode := TNodeLink(MMLinks.Items[i]);
      MMCombo.Items.Add(OneNode.sDescription);
    end;
    MMCombo.Enabled := True;
  end
  else
    MMCombo.Enabled := False;
end;


procedure TMMWnd.MMComboChange(Sender: TObject);
Var SelNode : TNodeLink;
begin
  SelNode := TNodeLink(MMLinks.Items[MMCombo.ItemIndex]);
  ReaderForm.ParseLinkRequest(SelNode.iNodeIdx);
end;

procedure TMMWnd.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  MediaPlayer1.Filename := '';
  MediaPlayer1.Wait := True;
  MediaPlayer1.Close;
end;

end.
