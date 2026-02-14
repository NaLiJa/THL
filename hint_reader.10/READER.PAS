unit reader;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons,Main, ExtCtrls;

type
  TReaderForm = class(TForm)
    TitleLabel: TLabel;
    UniLister: TListBox;
    BitBtn1: TBitBtn;
    ZusatzMemo: TMemo;
    TopicImg: TImage;
    PicImg: TImage;
    MMImg: TImage;
    HintImg: TImage;
    BackImg: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure UniListerDblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure UniListerDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure FormActivate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure UniListerClick(Sender: TObject);
  private
    { Private-Deklarationen }
    BackToken,
    HintToken  : string;
    MainList   : TList;
    IndexList  : TStringList;
    HintBools  : array[0..999] of Boolean;
    Messages   : array[1..4] of string;
    function ReadHFile( Filename : string ): Boolean;
    procedure SetInfos;
    procedure FillListAndIndex( NewIndex : Integer );
    function HintsRead :Boolean;
  public
    { Public-Deklarationen }
    Author : string;
    Title  : string;
    Zusatz : TStringList;
    function DecodeLine( Src,Passwd : string ):string;
    procedure ShowForm( Filename : string );
    procedure SetLanguage( HL : THandle );
  end;

  TRHint = class(TObject)
  private
  public
    RType    : EntryType;
    OwnRef   : Integer;
    SText    : string;
    HintText : TStringList;
    Filename : string;
    RectList : TStringList;
    DescList : TStringList;
    constructor Create(EType : EntryType);
    destructor Free;
    function GetRectFromDesc( Desc : string ):string;
  end;

var
  ReaderForm: TReaderForm;

implementation

uses hntwnd, MediaWnd, picview, CompWnd, LDMsgDlg;

{$R *.DFM}

{-------------------------- TRHint --------------------------------}
constructor TRHint.Create( EType : EntryType );
begin
  RType := EType;
  case EType of
  etHint : HintText := TStringList.Create;
  etPic  : begin
             RectList := TStringList.Create;
             DescList := TStringList.Create;
           end;
  end;
end;

destructor TRHint.Free;
Var FDel  : File;
begin
  case RType of
  etHint : HintText.Free;
  etPic  : begin
             RectList.Free;
             DescList.Free;
             AssignFile(FDel,Filename);
             try
               Erase(FDel);
             except
               on EInOutError do
                 LDMessageDlg(ReaderForm.Messages[4],mtError,[mbOK],0);
             end;
           end;
  etMM   : begin
             AssignFile(FDel,Filename);
             try
               Erase(FDel);
             except
               on EInOutError do
                 LDMessageDlg(ReaderForm.Messages[4],mtError,[mbOK],0);
             end;
           end;
  end;
end;


function TRHint.GetRectFromDesc( Desc : string ):string;
Var i    : Integer;
    sRes : string;
begin
  sRes := '';
  for i:=0 to DescList.Count-1 do
    if DescList[i] = Desc then
      sRes := RectList[i];
  GetRectFromDesc := sRes;
end;
{-------------------------- TRHint --------------------------------}

procedure TReaderForm.ShowForm( Filename : string );
begin
  if ReadHFile(Filename) then begin
    ZusatzMemo.Lines.Clear;
    SetInfos;
    FillListAndIndex( 0 );
    ShowModal;
  end;
end;

function TReaderForm.DecodeLine( Src,Passwd : string ):string;
Var DChar     : Char;
    i,dc      : Integer;
    Decrypted : string;
begin
  dc := 1;
  for i:=1 to Length(Src) do begin
    DChar := Passwd[dc];
    Decrypted := Decrypted + Chr( ord(Src[i]) - ord(DChar) );
    dc := (dc+1) mod Length(Passwd);
  end;
  DecodeLine := Decrypted;
end;

function TReaderForm.ReadHFile( Filename : string ): Boolean;
Var FCmp         : file of char;
    FPic         : file of char;
    FMM          : file of char;
    sTmp         : string;
    bRet         : Boolean;
    NewHint      : TRHint;
    RootHint     : TRHint;
    Buffer       : array[0..254] of char;
    NumRead,
    NumWritten   : Integer;
    i,j,k        : Integer;
    Sx,Sy,Ex,Ey  : Integer;
    iPos         : Integer;
    sCmd         : string;
    bDone        : Boolean;
    bLineDone    : Boolean;
    Cnt          : Integer;
    SingleCh     : char;
    TmpPath      : PChar;
    TmpFile      : Pchar;
    TmpCompl     : string;
    FileLength   : LongInt;
    sTmp2        : string;

   procedure VReadLn( Var Line : string );
   Var SubChar         : char;
       NextChar        : char;
       SubNumWritten,
       Subj            : Integer;
       bLineDone       : Boolean;
   begin
     Line := '';
     SubChar := chr(0);
     bLineDone := False;
     while (not bLineDone) do begin
       BlockRead(FCmp,SubChar,1,SubNumWritten);
       if SubChar <> #13 then
         Line:=Line+SubChar
       else begin
         BlockRead(FCmp,NextChar,1,SubNumWritten);
         if NextChar = #10 then
           bLineDone := True
         else begin
           Line:=Line+SubChar;
           Line:=Line+NextChar;
         end;
       end;
     end;
   end;

begin
MainList := TList.Create;
RootHint := TRHint.Create(etTopic);
RootHint.sText := '<<<ROOT>>>';
RootHint.OwnRef := -1;
MainList.Add(RootHint);
IndexList := TStringList.Create;
IndexList.Add('-1');
Zusatz.Clear;
try
  CmpWnd.Show;
  bRet := True;
  AssignFile(FCmp,Filename);
  Reset(FCmp);
  CmpWnd.SetTextLine('General data');
  { ...Daten lesen ! }
  { Version }
  VReadLn(sTmp);
  if StrToInt(sTmp) > StrToInt(PRG_VER) then begin
    LDMessageDlg(Messages[1],mtError,[mbOK],0);
    bRet := False;
  end
  else begin
    { Titel }
    VReadLn(sTmp);
    Title := DecodeLine(sTmp,'THL');
    { Schriftart }
    VReadLn(sTmp);
    TitleLabel.Font.Name := DecodeLine(sTmp,Title);
    VReadLn(sTmp);
    TitleLabel.Font.Color := StrToInt(DecodeLine(sTmp,Title));
    VReadLn(sTmp);
    TitleLabel.Font.Size := StrToInt(DecodeLine(sTmp,Title));
    VReadLn(sTmp);
    sTmp := DecodeLine(sTmp,Title);
    TitleLabel.Font.Style := [];
    if sTmp[1] = '1' then
      TitleLabel.Font.Style := TitleLabel.Font.Style + [fsBold];
    if sTmp[2] = '1' then
      TitleLabel.Font.Style := TitleLabel.Font.Style + [fsItalic];
    if sTmp[3] = '1' then
      TitleLabel.Font.Style := TitleLabel.Font.Style + [fsUnderline];
    if sTmp[4] = '1' then
      TitleLabel.Font.Style := TitleLabel.Font.Style + [fsStrikeOut];
    { Autor }
    VReadLn(sTmp);
    Author := DecodeLine(sTmp,Title);
    { Notiz }
    VReadLn(sTmp);
    if DecodeLine(sTmp,Title) = '#NOTICE<#' then begin
      VReadLn(sTmp);
      sTmp := DecodeLine(sTmp,Title);
      while sTmp <> '#>NOTICE#' do begin
        if sTmp <> '' then Zusatz.Add(sTmp);
        VReadLn(sTmp);
        sTmp := DecodeLine(sTmp,Title);
      end;
      VReadLn(sTmp);
      sTmp := DecodeLine(sTmp,Author);
      MainList.Capacity := StrToInt(sTmp);
      { Hinteinträge }
      while ((not eof(FCmp)) And (bRet)) do begin
        VReadLn(sTmp);
        sCmd := DecodeLine(sTmp,Author);
        if sCmd = '#TOPIC#' then begin
          CmpWnd.SetTextLine('Topic');
          NewHint := TRHint.Create(etTopic);
          VReadLn(sTmp);
          NewHint.OwnRef := StrToInt(DecodeLine(sTmp,Author));
          VReadLn(sTmp);
          NewHint.SText := DecodeLine(sTmp,Author);
          MainList.Add(NewHint);
        end;
        if sCmd = '#HINT#' then begin
          CmpWnd.SetTextLine('Hint');
          NewHint := TRHint.Create(etHint);
          VReadLn(sTmp);
          NewHint.OwnRef := StrToInt(DecodeLine(sTmp,Author));
          VReadLn(sTmp);
          if DecodeLine(sTmp,Author) = '#TEXT#' then begin
            VReadLn(sTmp);
            sTmp := DecodeLine(sTmp,Author);
            while (sTmp <> '#FINISH#') do begin
              NewHint.HintText.Add(sTmp);
              VReadLn(sTmp);
              sTmp := DecodeLine(sTmp,Author);
            end;
            MainList.Add(NewHint);
          end
          else begin
            LDMessageDlg(Messages[2],mtError,[mbOK],0);
            bRet := False;
          end;
        end;
        if sCmd = '#PIC#' then begin
          CmpWnd.SetTextLine('Picture');
          NewHint := TRHint.Create(etPic);
          VReadLn(sTmp);
          NewHint.OwnRef := StrToInt(DecodeLine(sTmp,Author));
          VReadLn(sTmp);
          sTmp := DecodeLine(sTmp,Author);
          { Windows Tempfile }
          try
            TmpPath := StrAlloc(255);
            TmpFile := StrAlloc(255);
            GetTempPath(255,TmpPath);
            GetTempFileName(TmpPath,'~thl',0,TmpFile);
            AssignFile(FPic,StrPas(TmpFile));
            Erase(FPic);
            NewHint.Filename := ChangeFileExt(StrPas(TmpFile),sTmp);
          finally
            StrDispose (TmpPath);
            StrDispose (TmpFile);
          end;
{
          NewHint.Filename := '~t'+IntToSTr(MainList.Count)+sTmp;
}
          try
            AssignFile(FPic,NewHint.Filename);
            Rewrite(FPic);
            bDone := False;
            VReadLn(sTmp2);
            FileLength := StrToInt(sTmp2);
            repeat
              For j:=0 to 254 do Buffer[j]:= chr(0);
              if FileLength > 255 then begin
                BlockRead(FCmp,Buffer,sizeof(Buffer),NumRead);
                BlockWrite(FPic,Buffer,NumRead,NumWritten);
                Dec(FileLength,255);
              end
              else begin
                BlockRead(FCmp,Buffer,FileLength,NumRead);
                BlockWrite(FPic,Buffer,NumRead,NumWritten);
                FileLength := 0;
              end;
            until FileLength = 0;
            VReadLn(sTmp);
          finally
            CloseFile(FPic);
          end;
          if DecodeLine(sTmp,Author) <> '#PICEND#' then begin
            LDMessageDlg(Messages[2],mtError,[mbOK],0);
            bRet := False;
          end
          else begin
            VReadLn(sTmp);
            for i := 1 to StrToInt(DecodeLine(sTmp,Author)) do begin
              VReadLn(sTmp);
              sTmp := DecodeLine(sTmp,Author);
              NewHint.DescList.Add(sTmp);
              VReadLn(sTmp);
              sTmp := DecodeLine(sTmp,Author);
              NewHint.RectList.Add(sTmp);
            end;
          end;
          MainList.Add(NewHint);
        end;
        if sCmd = '#MM#' then begin
          CmpWnd.SetTextLine('Multimedia file');
          NewHint := TRHint.Create(etMM);
          VReadLn(sTmp);
          NewHint.OwnRef := StrToInt(DecodeLine(sTmp,Author));
          VReadLn(sTmp);
          sTmp := DecodeLine(sTmp,Author);
          { Windows Tempfile }
          try
            TmpPath := StrAlloc(255);
            TmpFile := StrAlloc(255);
            GetTempPath(255,TmpPath);
            GetTempFileName(TmpPath,'~thl',0,TmpFile);
            AssignFile(FMM,StrPas(TmpFile));
            Erase(FMM);
            NewHint.Filename := ChangeFileExt(StrPas(TmpFile),sTmp);
          finally
            StrDispose (TmpPath);
            StrDispose (TmpFile);
          end;
          VReadLn(sTmp);
          sTmp := DecodeLine(sTmp,Author);
          NewHint.sText := sTmp;
          try
            AssignFile(FMM,NewHint.Filename);
            Rewrite(FMM);
            bDone := False;
            VReadLn(sTmp2);
            FileLength := StrToInt(sTmp2);
            repeat
              For j:=0 to 254 do Buffer[j]:= chr(0);
              if FileLength > 255 then begin
                BlockRead(FCmp,Buffer,sizeof(Buffer),NumRead);
                BlockWrite(FMM,Buffer,NumRead,NumWritten);
                Dec(FileLength,255);
              end
              else begin
                BlockRead(FCmp,Buffer,FileLength,NumRead);
                BlockWrite(FMM,Buffer,NumRead,NumWritten);
                FileLength := 0;
              end;
            until FileLength = 0;
            VReadLn(sTmp);
          finally
            CloseFile(FMM);
          end;
          if DecodeLine(sTmp,Author) <> '#MMEND#' then begin
            LDMessageDlg(Messages[2],mtError,[mbOK],0);
            bRet := False;
          end
          else
            MainList.Add(NewHint);
        end;
      end; { while }
    end
    else begin
      LDMessageDlg(Messages[2],mtError,[mbOK],0);
      bRet := False;
    end;
  end; { Version }
finally
  CmpWnd.Close;
  Closefile(FCmp);
end;
ReadHFile := bRet;
end;

procedure TReaderForm.FormCreate(Sender: TObject);
begin
  Zusatz := TStringList.Create;
end;

procedure TReaderForm.FormDestroy(Sender: TObject);
begin
  Zusatz.Free;
end;

procedure TReaderForm.BitBtn1Click(Sender: TObject);
begin
  Close;
end;

procedure TReaderForm.SetInfos;
begin
  TitleLabel.Caption := Title;
  if Zusatz.Count > 0 then
    ZusatzMemo.Lines := Zusatz;
  ZusatzMemo.Lines.Insert(0,Author);
end;

procedure TReaderForm.FillListAndIndex( NewIndex : Integer );
Var OneHint   : TRHint;
    CurrList  : TStringList;
    i,j       : Integer;
    sBackup   : string;
    iHintCnt  : Integer;
begin
  CurrList := TStringList.Create;
  if NewIndex <> 0 then begin
    OneHint := MainList[StrToInt(IndexList[1])];
    sBackup := IntToStr(OneHint.OwnRef);
  end;
  IndexList.Clear;
  IndexList.Add('-1');
  iHintCnt := 0;
  for i:= 0 to 999 do
    HintBools[i] := False;
  for i:=1 to MainList.Count-1 do begin
    OneHint := MainList.Items[i];
    if OneHint.OwnRef = NewIndex then begin
      case OneHint.RType of
        etTopic : begin
                    CurrList.Add( OneHint.sText );
                    IndexList.Add(IntToStr(i));
                  end;
        etHint  : begin
                    Inc(iHintCnt);
                    CurrList.Add( HintToken + IntToStr(iHintCnt));
                    IndexList.Add(IntToStr(i));
                  end;
        etPic   : begin
                     for j:=0 to OneHint.DescList.Count-1 do begin
                       CurrList.Add( OneHint.DescList[j]);
                       IndexList.Add(IntToStr(i));
                     end;
                  end;
        etMM    : begin
                    CurrList.Add( OneHint.sText);
                    IndexList.Add(IntToStr(i));
                  end;
      end;
    end;
  end;
  if NewIndex > 0 then begin
    CurrList.Add(BackToken);
    if CurrList.Count <= 1 then
      IndexList.Add(sBackup);
  end;
  if CurrList.Count > 0 then
    UniLister.Items := CurrList;
  CurrList.Free;
end;

procedure TReaderForm.UniListerDblClick(Sender: TObject);
Var TheHint : TRHint;
    i       : integer;
    wRes    : Word;
begin
  if UniLister.Items[UniLister.ItemIndex] = Backtoken then begin
    if UniLister.Items.Count > 1 then begin
      TheHint := MainList.Items[StrToInt(IndexList[1])];
      TheHint := MainList.Items[TheHint.OwnRef];
      FillListAndIndex(TheHint.OwnRef);
    end
    else
      FillListAndIndex(StrToInt(IndexList[1]));
  end
  else begin
    i:=StrToInt(IndexList[UniLister.ItemIndex+1]);
    TheHint := MainList.Items[i];
    case TheHint.RType of
    etTopic : FillListAndIndex(i);
    etHint  : begin
                wRes := mrYes;
                if not HintsRead then
                  wRes := LDMessageDlg(Messages[3],mtConfirmation,[mbYES,mbNO],0);
                if wRes = mrYes then begin
                  HintWindow.HintMemo.Lines := TheHint.HintText;
                  HintWindow.ShowModal;
                  HintBools[UniLister.ItemIndex] := True;
                end;
              end;
    etPic   : begin
                ShowPic.WindowState := wsNormal;
                ShowPic.Show;
                ShowPic.SetPicture(TheHint.Filename,
                                   TheHint.GetRectFromDesc(
                                   UniLister.Items[UniLister.ItemIndex]));
              end;
    etMM    : begin
                MMWnd.Label1.Caption := TheHint.sText;
                MMWnd.MediaPlayer1.Filename := TheHint.Filename;
                MMWnd.MediaPlayer1.Open;
                MMWnd.ShowModal;
              end;
    end;
  end;
end;

procedure TReaderForm.FormClose(Sender: TObject; var Action: TCloseAction);
Var i   : Integer;
    cH  : TRHint;
begin
  if MainList.Count > 0 then
    For i:=0 to MainList.Count-1 do begin
      cH := MainList.Items[i];
      cH.Free;
    end;
  MainList.Free;
  IndexList.Free;
end;

procedure TReaderForm.UniListerDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  Offset   : Integer;	{ Abstand zum Text }  TheHint  : TRHint;  i        : Integer;  TheIcon  : TIcon;begin  with (Control as TListBox).Canvas do	{ Zeichnen auf der Zeichenfläche des }	{ Dialogelements, nicht auf dem Formular }  begin    FillRect(Rect);	{ Rechteck löschen }

    Offset := 2;	{ Standardabstand bereitstellen }
    if UniLister.Items[Index] = Backtoken then
      TheIcon := BackImg.Picture.Icon
    else begin
      TheHint := MainList.Items[StrToInt(IndexList[Index+1])];
      case TheHint.RType of
      etTopic : TheIcon := TopicImg.Picture.Icon;
      etHint  : TheIcon := HintImg.Picture.Icon;
      etPic   : TheIcon := PicImg.Picture.Icon;
      etMM    : TheIcon := MMImg.Picture.Icon;
      end;
    end;
    Draw(Rect.Left + 2, Rect.Top,TheIcon);
    Offset := TheIcon.width + 6;{ Vier Pixel zwischen Text und Icon hinzufügen }
    TextOut(Rect.Left + Offset, Rect.Top+5,UniLister.Items[Index])	{ Text anzeigen }
  end;
end;

procedure TReaderForm.SetLanguage( HL : THandle );
Var Buffer : array[0..254] of char;
begin
  LoadString(HL,300,Buffer,sizeof(Buffer));
  ReaderForm.Caption := StrPas(Buffer);
  LoadString(HL,301,Buffer,sizeof(Buffer));
  BitBtn1.Caption := StrPas(Buffer);;
  LoadString(HL,302,Buffer,sizeof(Buffer));
  BackToken := StrPas(Buffer);
  LoadString(HL,303,Buffer,sizeof(Buffer));
  HintToken := StrPas(Buffer);
  LoadString(HL,304,Buffer,sizeof(Buffer));
  Messages[1] := StrPas(Buffer);
  LoadString(HL,305,Buffer,sizeof(Buffer));
  Messages[2] := StrPas(Buffer);
  LoadString(HL,306,Buffer,sizeof(Buffer));
  Messages[3] := StrPas(Buffer);
end;

procedure TReaderForm.FormActivate(Sender: TObject);
begin
  WindowState := wsNormal;
end;

function TReaderForm.HintsRead: Boolean;
Var bRet : Boolean;
    i    : Integer;
    TheHint : TRHint;
begin
  bRet := True;
  for i:=0 to UniLister.ItemIndex-1 do begin
    TheHint := MainList.Items[StrToInt(IndexList[i+1])];
    if (TheHint.RType = etHint) And (not HintBools[i]) then
      bRet := False;
  end;
  HintsRead := bRet;
end;
procedure TReaderForm.FormResize(Sender: TObject);
begin
  TitleLabel.Width := ReaderForm.ClientWidth-16;
  UniLister.Width := ReaderForm.ClientWidth-16;
  ZusatzMemo.Width := ReaderForm.ClientWidth-16;
  BitBtn1.Left := (ReaderForm.ClientWidth-BitBtn1.Width)div 2;
  BitBtn1.Top := ReaderForm.ClientHeight-40;
  ZusatzMemo.Top := ReaderForm.ClientHeight-120;
  UniLister.Height := ClientHeight-UniLister.Top-130;
end;

procedure TReaderForm.UniListerClick(Sender: TObject);
begin
  UniLister.Hint := UniLister.Items[UniLister.ItemIndex];
end;

end.
