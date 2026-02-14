unit pcedit;

{ LANG TEXT RANGE: 250-261 }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons,Main, Grids, Gauges, ExtCtrls, DMTools;

type
  TPicEdit = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    OpenPic: TOpenDialog;
    StringGrid1: TStringGrid;
    GroupBox1: TGroupBox;
    Edit1: TEdit;
    BitBtn3: TBitBtn;
    Label1: TLabel;
    Label3: TLabel;
    ScrollBox1: TScrollBox;
    Image1: TImage;
    Gauge1: TGauge;
    Image2: TImage;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
  private
    bLoadErr : Boolean;
    IsValid : Boolean;
    Messages : array[1..5] of string;
    pointStart: TPoint;
    pointEnd  : TPoint;
    bLeftDown : boolean;
    procedure DrawRubberband;
    procedure ErrorHandler(Fehler: word; Name: string);
    function LoadPicture(BildName: string): bool;
    { Private-Deklarationen }
  public
    function MakeNew:TStringsPack;
    procedure EditEntry(Var OldPack : TStringsPack );
    procedure SetLanguage( HL : THandle );
  end;

var
  PicEdit: TPicEdit;

implementation
uses MPVdaten, MPVsize, ShellAPI,DMGMain, DMGBasic, DMGColor, DMGSize, DMGrBMP,
     DMGrJPEG,MPVOpts,LDMsgDlg;

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
  PicEdit.Gauge1.Progress := Wert;
  {------------ MultiTasking ausführen}
  Application.ProcessMessages;
  DMGrafik_CallBack := UserAbort;
end {function DMGrafik_CallBack};
{==============================================	DMGrafik_CallBack}


function TPicEdit.MakeNew;
Var spTmp : TStringsPack;
    i     : Integer;
begin
  PicEdit.Edit1.Text := '';
  for i:= 1 to 24 do begin
    StringGrid1.Cells[0,i] := '';
    StringGrid1.Cells[1,i] := '';
  end;
  bLoadErr := False;
  Image1.Picture.Bitmap.Height := 0;
  Image1.Picture.Bitmap.Width := 0;
  PicEdit.ShowModal;
  spTmp := TStringsPack.Create;
  if IsValid then begin
    spTmp.sSimple := PicEdit.Edit1.Text;
    for i:=1 to 24 do begin
      if (StringGrid1.Cells[0,i]<>'') AND
         (StringGrid1.Cells[1,i]<>'') then begin
        spTmp.sComplex.Add(StringGrid1.Cells[0,i]);
        spTmp.sComplex2.Add(StringGrid1.Cells[1,i]);
      end;
    end;
  end;
  MakeNew := spTmp;
end;

procedure TPicEdit.BitBtn1Click(Sender: TObject);
Var bComplete : Boolean;
    i         : Integer;
begin
  bComplete := True;
  for i:=1 to 24 do
    if (((StringGrid1.Cells[0,i]='') AND (StringGrid1.Cells[1,i]<>'')) OR
        ((StringGrid1.Cells[0,i]<>'') AND (StringGrid1.Cells[1,i]=''))) then
      bComplete := False;
  if not bComplete then
    LDMessageDlg(Messages[1],mtError,[mbOK],0)
  else begin
    if FileExists(Edit1.Text) then begin
      IsValid := True;
      Close;
    end
    else
      LDMessageDlg(Messages[2],mtError,[mbOK],0);
  end;
end;

procedure TPicEdit.BitBtn2Click(Sender: TObject);
begin
  IsValid := False;
  Close;
end;

procedure TPicEdit.BitBtn3Click(Sender: TObject);
Var i    : Integer;
    wRes : Word;
begin
  if OpenPic.Execute then begin
    Edit1.Text := OpenPic.Filename;
    wRes := mrYes;
    if bLoadErr then
      wRes := LDMessageDlg(Messages[5],mtConfirmation,[mbYES,mbNO],0);
    if wRes = mrYes then
      for i:= 1 to 24 do begin
        StringGrid1.Cells[0,i] := '';
        StringGrid1.Cells[1,i] := '';
      end;
    if mg_CheckFormat(pChar(ExtractFileExt(PicEdit.Edit1.Text))) then
      if LoadPicture( PicEdit.Edit1.Text ) then begin
        if wRes = mrYes then begin
          StringGrid1.Cells[0,1] := '<Komplettes Bild; Complete picture>';
          StringGrid1.Cells[1,1] := IntToStr(0)+','+IntToStr(0)+','+
                                    IntToStr(Image1.Picture.Width)+','+
                                    IntToStr(Image1.Picture.Height);
        end;
        bLoadErr := False;
      end
      else
        Edit1.Text := '';
  end;
end;

procedure TPicEdit.EditEntry(Var OldPack : TStringsPack);
Var spTmp : TStringsPack;
    i     : Integer;
begin
  PicEdit.Edit1.Text := OldPack.sSimple;
  if FileExists(PicEdit.Edit1.Text) then begin
    LoadPicture( PicEdit.Edit1.Text );
    bLoadErr := False;
  end
  else begin
    LDMessageDlg(Messages[2],mtError,[mbOK],0);
    Image1.Picture.Bitmap.Height := 0;
    Image1.Picture.Bitmap.Width := 0;
    bLoadErr := True;
  end;
  for i := 0 to OldPack.sComplex.Count-1 do begin
    StringGrid1.Cells[0,i+1] := OldPack.sComplex[i];
    StringGrid1.Cells[1,i+1] := OldPack.sComplex2[i];
  end;
  PicEdit.ShowModal;
  if IsValid then begin
    spTmp := TStringsPack.Create;
    spTmp.sSimple := PicEdit.Edit1.Text;
    for i:=1 to 24 do begin
      if (StringGrid1.Cells[0,i]<>'') AND
       (StringGrid1.Cells[1,i]<>'') then begin
          spTmp.sComplex.Add(StringGrid1.Cells[0,i]);
          spTmp.sComplex2.Add(StringGrid1.Cells[1,i]);
      end;
    end;
    OldPack := spTmp;
  end;
end;


procedure TPicEdit.SetLanguage( HL : THandle );
Var Buffer : array[0..254] of char;
begin
  LoadString(HL,250,Buffer,sizeof(Buffer));
  PicEdit.StringGrid1.Cells[0,0] := StrPas(Buffer);
  LoadString(HL,251,Buffer,sizeof(Buffer));
  PicEdit.StringGrid1.Cells[1,0] := StrPas(Buffer);
  LoadString(HL,252,Buffer,sizeof(Buffer));
  PicEdit.Caption := StrPas(Buffer);
  LoadString(HL,253,Buffer,sizeof(Buffer));
  PicEdit.Label1.Caption := StrPas(Buffer);
  LoadString(HL,254,Buffer,sizeof(Buffer));
  PicEdit.Label3.Caption := StrPas(Buffer);
  LoadString(HL,255,Buffer,sizeof(Buffer));
  PicEdit.BitBtn3.Caption := StrPas(Buffer);
  LoadString(HL,256,Buffer,sizeof(Buffer));
  PicEdit.BitBtn2.Caption := StrPas(Buffer);
  LoadString(HL,257,Buffer,sizeof(Buffer));
  Messages[1] := StrPas(Buffer);
  LoadString(HL,258,Buffer,sizeof(Buffer));
  Messages[2] := StrPas(Buffer);
  LoadString(HL,259,Buffer,sizeof(Buffer));
  Messages[3] := StrPas(Buffer);
  LoadString(HL,260,Buffer,sizeof(Buffer));
  Messages[4] := StrPas(Buffer);
  LoadString(HL,261,Buffer,sizeof(Buffer));
  Messages[5] := StrPas(Buffer);
  LoadString(HL,262,Buffer,Sizeof(Buffer));
  PicEdit.BitBtn1.Caption := StrPas(Buffer);
end;

function TPicEdit.LoadPicture(BildName: string): bool;
var
Bitmap          : hBitmap;
NewDIB          : pBitmapInfo;
Measure         : LongRec;
begin
  Result := false;
  NewDIB := mg_LoadThePicture(pChar(Bildname), true);
  if (NewDIB = nil)
  then begin
       ErrorHandler(mg_GetLastError, BildName);
       PicEdit.Gauge1.Progress := 0;
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
       {-------- BMP in ImageObjekt einklinken}
       Image1.Picture.Bitmap.Handle := Bitmap;
       {-------- Erfolg vermerken}
       Result := true;
  end;
  PicEdit.Gauge1.Progress := 0;
end ;

procedure TPicEdit.FormCreate(Sender: TObject);
begin
  mg_SetTheCallBack(@DMGrafik_CallBack);
end;

procedure TPicEdit.FormActivate(Sender: TObject);
begin
  PicEdit.StringGrid1.ColWidths[0] := 380;
  PicEdit.StringGrid1.ColWidths[1] := 135;
end;

procedure TPicEdit.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  bLeftDown := false;
  if button = mbLeft then begin
    bLeftDown := true;
    pointStart.X := X;
    pointStart.Y := Y;
    pointEnd.X := X;
    pointEnd.Y := Y;
  end;
end;

procedure TPicEdit.Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if not bLeftDown then exit;
  DrawRubberband;
  pointEnd.x := X;
  pointEnd.y := Y;
  DrawRubberband;
end;

procedure TPicEdit.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
Var sArea   : string;
    iHit    : integer;
    bFound  : Boolean;
begin
  if not bLeftDown then exit;
  DrawRubberband;
  bLeftDown := false;
  pointEnd.X := X;
  pointEnd.Y := Y;
  sArea := IntToStr(pointStart.x)+','+IntToStr(pointStart.y)+','+
           IntToStr(pointEnd.x)+','+IntToStr(pointEnd.y);
  if LDMessageDlg(Messages[3]+#13+sArea,mtConfirmation,
                [mbYES,mbNO],0) = mrYES then begin
    iHit := 1;
    bFound := False;
    while (iHit<=24) and (not bFound) do
      if ((StringGrid1.Cells[0,iHit]='') and
          (StringGrid1.Cells[1,iHit]='')) then bFound := True
      else
        Inc(iHit);
    if not bFound then
      LDMessageDlg(Messages[4],mtError,[mbOK],0)
    else
      StringGrid1.Cells[1,iHit] := sArea;
  end;
end;

procedure TPicEdit.DrawRubberband;
begin
  SetROP2(Image1.Canvas.handle, R2_NOT);
  Image1.Canvas.moveto(pointStart.x, pointStart.y);
  Image1.Canvas.lineto(pointStart.x, pointEnd.y);
  Image1.Canvas.lineto(pointEnd.x, pointEnd.y);
  Image1.Canvas.lineto(pointEnd.x, pointStart.y);
  Image1.Canvas.lineto(pointStart.x, pointStart.y);
end;

{----------------------------------------------	FehlerBehandeln}
procedure TPicEdit.ErrorHandler(Fehler: word; Name: string);
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

procedure TPicEdit.FormResize(Sender: TObject);
Var Space : Integer;
begin
  GroupBox1.Width := ClientWidth-16;
  Edit1.Width := GroupBox1.Width-16-10-BitBtn3.Width;
  BitBtn3.Left := GroupBox1.Width-8-BitBtn3.Width;
  StringGrid1.Width := ClientWidth-16;
  PicEdit.StringGrid1.ColWidths[0] := Round(76 * ((ClientWidth-21)/103));
  PicEdit.StringGrid1.ColWidths[1] := Round(27 * ((ClientWidth-21)/103));
  ScrollBox1.Width := ClientWidth-16;
  ScrollBox1.Height := ClientHeight-ScrollBox1.Top-48;
  BitBtn1.Top := ClientHeight-36;
  BitBtn2.Top := ClientHeight-36;
  Image2.Top := ClientHeight-5-Image2.Height;
  Gauge1.Top := ClientHeight-5-Gauge1.Height;
  Gauge1.Left := ClientWidth-8-Gauge1.Width;
  Space := Round((ClientWidth-16-Image2.Width-Gauge1.Width-BitBtn1.Width
           -BitBtn2.Width)/3);
  BitBtn1.Left := 8+Image2.Width+Space;
  BitBtn2.Left := 8+Image2.Width+2*Space+BitBtn1.Width;         
end;

end.
