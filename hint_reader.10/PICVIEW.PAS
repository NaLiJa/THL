unit picview;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, StdCtrls, Buttons, MPlayer, Gauges, DMTools, Main;

type
  TShowPic = class(TForm)
    ScrollBox1: TScrollBox;
    Image1: TImage;
    BitBtn1: TBitBtn;
    Gauge1: TGauge;
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure ErrorHandler(Fehler: word; Name: string);
    { Private-Deklarationen }
  public
    function SetPicture(BildName, RectStr: string): bool;
    procedure SetLanguage( HL : THandle );
    { Public-Deklarationen }
  end;

var
  ShowPic: TShowPic;

implementation
uses MPVdaten, MPVsize, ShellAPI,DMGMain, DMGBasic, DMGColor, DMGSize, DMGrBMP,
     DMGrJPEG,MPVOpts;

{$R *.DFM}

{==============================================	DMGrafik_CallBack}
function DMGrafik_CallBack(wMsg: word; cProgress: longint): bool; stdcall;
var
Wert		: longint;
begin
  DMGrafik_CallBack := UserAbort;
  if UserAbort then exit;
  {------------ Aus der Botschaft Message zusammenstellen}
  case wMsg of
       DMG_Expand,
       DMG_Repack,
       DMG_Resize,
       DMG_ChgToGray,
       DMG_ExpToTrue,
       DMG_Histogramm,
       DMG_Remap,
       DMG_ChgTo256  : Wert := cProgress;
       {------- alle anderen Meldungen ignorieren}
       else Wert := 0;
  end {case mMsg of};
  ShowPic.Gauge1.Progress := Wert;
  {------------ MultiTasking ausführen}
  Application.ProcessMessages;
  DMGrafik_CallBack := UserAbort;
end {function DMGrafik_CallBack};
{==============================================	DMGrafik_CallBack}

procedure TShowPic.FormResize(Sender: TObject);
begin
  ScrollBox1.Width := ClientWidth;
  ScrollBox1.Height := ClientHeight-43;
  BitBtn1.Top := ClientHeight-37;
  BitBtn1.Left := ClientWidth-107;
  Gauge1.Top := ClientHeight-37;
end;

{----------------------------------------------	FehlerBehandeln}
procedure TShowPic.ErrorHandler(Fehler: word; Name: string);
begin
  case Fehler of
       {-------- StandardErrors}
       MTERR_STDFIRST..MTERR_STDLAST:
          mt_StandardError(Fehler);
       {-------- ExtendedErrors}
       MTERR_EXTFIRST..MTERR_EXTLAST:
          mt_ExtendedError(Fehler, #13#10 + Name);
       {-------- GrafikErrors}
       MGERR_First..MGERR_Last :
          mg_GrafikFehler(Application.Handle, pChar(Application.Title),
                          pChar(#13+#10+Name), Fehler);
       {-------- ApplicationErrors}
       app_FirstError..app_LastError:
          mt_ApplicationError(Fehler, #13#10 + Name);
       {-------- Unbekannter Fehler}
       else mt_StandardError(MTERR_UNKNOWN);
  end;
end;

function TShowPic.SetPicture(BildName,RectStr: string): bool;
var
Bitmap          : hBitmap;
NewDIB          : pBitmapInfo;
Measure         : LongRec;
sX,sY,eX,eY     : Integer;
iPos            : Integer;
tmpBmp          : TBitmap;
begin
  Result := false;
  NewDIB := mg_LoadThePicture(pChar(Bildname), true);
  if (NewDIB = nil)
  then begin
       ErrorHandler(mg_GetLastError, BildName);
       ShowPic.Gauge1.Progress := 0;
       exit;
  end;
  {------------- voriges DIB löschen}
  mg_FreeTheDIB(MemDIB);
  {------------- für Bildbearbeitungsfunktionen DIB aufheben}
  MemDIB := NewDIB;
  Measure := LongRec(mg_GetDIBMeasure(NewDIB));
  MemWid := Measure.Lo;
  MemHei := Measure.Hi;
  {------------- DIB in BMP konvertieren}
  Bitmap := mg_MakeBMPfromDIB(MemDIB);
  {------------- Fehler?}
  if (Bitmap = 0)
  then ErrorHandler(app_ConvertToBMP, BildName)
  else begin
    iPos := Pos(',',RectStr);
    sX := StrToInt(Copy(RectStr,1,iPos-1));
    Delete(RectStr,1,iPos);
    iPos := Pos(',',RectStr);
    sY := StrToInt(Copy(RectStr,1,iPos-1));
    Delete(RectStr,1,iPos);
    iPos := Pos(',',RectStr);
    eX := StrToInt(Copy(RectStr,1,iPos-1));
    Delete(RectStr,1,iPos);
    eY := StrToInt(RectStr);
    Image1.Picture.Bitmap.Width := eX-sX;
    Image1.Picture.Bitmap.Height := eY-sY;
    try
      tmpBmp := TBitmap.Create;
      tmpBmp.Height := eY-sY;
      tmpBmp.Width := eX-sX;
      tmpBmp.Handle := Bitmap;
      Image1.Picture.Bitmap.Canvas.CopyRect(Rect(0,0,eX-sX,eY-sY),tmpBmp.canvas,
                                            Rect(sX,sY,eX,eY));
    finally
      tmpBmp.Free;
    end;
    Result := true;
  end;
  ShowPic.Gauge1.Progress := 0;
end ;

procedure TShowPic.FormCreate(Sender: TObject);
begin
  mg_SetTheCallBack(@DMGrafik_CallBack);
end;

procedure TShowPic.SetLanguage( HL : THandle );
Var Buffer : array[0..254] of char;
begin
  LoadString(HL,350,Buffer,sizeof(Buffer));
  ShowPic.Caption := StrPas(Buffer);
  LoadString(HL,351,Buffer,sizeof(Buffer));
  BitBtn1.Caption := StrPas(Buffer);
end;

end.
