unit whatsnew;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TWasNeues = class(TForm)
    Memo1: TMemo;
  private
    ExtFile : string;
    { Private-Deklarationen }
  public
    procedure SetLanguage( HL : THandle );
    procedure ShowForm(Version : string);
  end;

var
  WasNeues: TWasNeues;

implementation

{$R *.DFM}

procedure TWasNeues.SetLanguage( HL : THandle );
Var Buffer : array[0..254] of char;
begin
  LoadString(HL,125,Buffer,sizeof(Buffer));
  WasNeues.Caption := StrPas(Buffer);
  LoadString(HL,126,Buffer,sizeof(Buffer));
  ExtFile := StrPas(Buffer);
end;

procedure TWasNeues.ShowForm( Version : string );
Var Datei : string;
begin
  Datei := ExtractFilePath(Application.Exename)+ExtFile+Version;
  if FileExists(Datei) then begin
    Memo1.Lines.LoadFromFile(Datei);
    ShowModal;
  end;
end;

end.
