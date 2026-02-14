unit MediaWnd;

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
    procedure BitBtn1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    procedure SetLanguage( HL : THandle );
    { Public-Deklarationen }
  end;

var
  MMWnd: TMMWnd;

implementation

{$R *.DFM}

procedure TMMWnd.BitBtn1Click(Sender: TObject);
begin
  MediaPlayer1.Filename := '';
  MediaPlayer1.Wait := True;
  MediaPlayer1.Close;
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

end.
