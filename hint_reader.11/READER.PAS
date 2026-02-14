unit reader;

{ LANG TEXT RANGE: 300-306 }
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons,Main, ExtCtrls;

type
  TReaderForm = class(TForm)
    UniLister: TListBox;
    BitBtn1: TBitBtn;
    ZusatzMemo: TMemo;
    TopicImg: TImage;
    PicImg: TImage;
    MMImg: TImage;
    HintImg: TImage;
    BackImg: TImage;
    InfoImg: TImage;
    TitleBox: TLabel;
    TopicCombo: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure UniListerDblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure UniListerDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure FormResize(Sender: TObject);
    procedure UniListerClick(Sender: TObject);
    procedure UniListerMeasureItem(Control: TWinControl; Index: Integer;
      var Height: Integer);
    procedure TopicComboChange(Sender: TObject);
  private
    { Private-Deklarationen }
    BackToken,
    HintToken   : string;
    MainList    : TList;
    IndexList   : TStringList;
    HintBools   : array[0..999] of Boolean;
    Messages    : array[1..4] of string;
    TopicLinks  : TList;
    InfoWndLine : string;
    InfoCapLine : string;
    function ReadHFile( Filename : string ): Boolean;
    procedure SetInfos;
    procedure FillListAndIndex( NewIndex : Integer );
    function HintsRead :Boolean;
    procedure FillComboBox;
  public
    { Public-Deklarationen }
    Author : string;
    Title  : string;
    Zusatz : TStringList;
    function DecodeLine( Src,Passwd : string ):string;
    procedure ShowForm( Filename : string );
    procedure SetLanguage( HL : THandle );
    procedure ParseLinkRequest( iIndex : Integer );
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
    Links    : TList;
    constructor Create(EType : EntryType);
    destructor Free;
    function GetRectFromDesc( Desc : string ):string;
  end;

var
  ReaderForm: TReaderForm;

implementation

uses hntwnd, MediaWnd, picview, CompWnd, LDMsgDlg, InfoWnd;

{$R *.DFM}

{-------------------------- TRHint --------------------------------}
constructor TRHint.Create( EType : EntryType );
begin
  RType := EType;
  case EType of
  etHint : HintText := TStringList.Create;
  etInfo : HintText := TStringList.Create;
  etPic  : begin
             RectList := TStringList.Create;
             DescList := TStringList.Create;
           end;
  end;
  Links := TList.Create;
end;

destructor TRHint.Free;
Var FDel  : File;
begin
  case RType of
  etHint : HintText.Free;
  etInfo : HintText.Free;
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
  Links.Free;
end;


function TRHint.GetRectFromDesc( Desc : string ):string;
Var i    : Integer;
    sRes : string;
begin
  sRes := '';
  if Desc = '~~~$$$###ALL###$$$~~~' then
    sRes := RectList[0]
  else begin
    for i:=0 to DescList.Count-1 do
      if DescList[i] = Desc then
        sRes := RectList[i];
  end;
  GetRectFromDesc := sRes;
end;
{-------------------------- TRHint --------------------------------}

procedure TReaderForm.ShowForm( Filename : string );
begin
  if ReadHFile(Filename) then begin
    UniLister.Hint := '';
    ZusatzMemo.Lines.Clear;
    SetInfos;
    FillListAndIndex( 0 );
    if WindowState <> wsNormal then
      WindowState := wsNormal;
    Show;
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
    i,j,k,l      : Integer;
    Sx,Sy,Ex,Ey  : Integer;
    iPos         : Integer;
    Ecount       : Integer;
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
    LinkEntry    : TNodeLink;
    FileVer      : Integer;

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
  CmpWnd.SetCaption(InfoCapLine,InfoWndLine);
  CmpWnd.Show;
  bRet := True;
  AssignFile(FCmp,Filename);
  Reset(FCmp);
  CmpWnd.SetTextLine('General data');
  { ...Daten lesen ! }
  { Version }
  VReadLn(sTmp);
  FileVer := StrToInt(sTmp);
  if FileVer > StrToInt(PRG_VER) then begin
    LDMessageDlg(Messages[1],mtError,[mbOK],0);
    bRet := False;
  end
  else begin
    { Titel }
    VReadLn(sTmp);
    Title := DecodeLine(sTmp,'THL');
    { Schriftart }
    VReadLn(sTmp);
    TitleBox.Font.Name := DecodeLine(sTmp,Title);
    VReadLn(sTmp);
    TitleBox.Font.Color := StrToInt(DecodeLine(sTmp,Title));
    VReadLn(sTmp);
    TitleBox.Font.Size := StrToInt(DecodeLine(sTmp,Title));
    VReadLn(sTmp);
    sTmp := DecodeLine(sTmp,Title);
    TitleBox.Font.Style := [];
    if sTmp[1] = '1' then
      TitleBox.Font.Style := TitleBox.Font.Style + [fsBold];
    if sTmp[2] = '1' then
      TitleBox.Font.Style := TitleBox.Font.Style + [fsItalic];
    if sTmp[3] = '1' then
      TitleBox.Font.Style := TitleBox.Font.Style + [fsUnderline];
    if sTmp[4] = '1' then
      TitleBox.Font.Style := TitleBox.Font.Style + [fsStrikeOut];
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
          if FileVer > 100 then begin
            VReadLn(sTmp);
            if DecodeLine(sTmp,Title) = '#LINKS#' then begin
              VReadLn(sTmp);
              sTmp := DecodeLine(sTmp,Title);
              ECount := StrToInt(sTmp);
              for l:=1 to ECount do begin
                LinkEntry := TNodeLink.Create;
                VReadLn(sTmp);
                LinkEntry.sDescription := DecodeLine(sTmp,Title);
                VReadLn(sTmp);
                LinkEntry.iNodeIdx := StrToInt(DecodeLine(sTmp,Title));
                NewHint.Links.Add(LinkEntry);
              end;
            end
            else begin
              LDMessageDlg(Messages[2],mtError,[mbOK],0);
              bRet := False;
            end;
          end;
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
            if FileVer > 100 then begin
              VReadLn(sTmp);
              if DecodeLine(sTmp,Title) = '#LINKS#' then begin
                VReadLn(sTmp);
                sTmp := DecodeLine(sTmp,Title);
                ECount := StrToInt(sTmp);
                for l:=1 to ECount do begin
                  LinkEntry := TNodeLink.Create;
                  VReadLn(sTmp);
                  LinkEntry.sDescription := DecodeLine(sTmp,Title);
                  VReadLn(sTmp);
                  LinkEntry.iNodeIdx := StrToInt(DecodeLine(sTmp,Title));
                  NewHint.Links.Add(LinkEntry);
                end;
              end
              else begin
                LDMessageDlg(Messages[2],mtError,[mbOK],0);
                bRet := False;
              end;
            end;
            MainList.Add(NewHint);
          end
          else begin
            LDMessageDlg(Messages[2],mtError,[mbOK],0);
            bRet := False;
          end;
        end;
        if sCmd = '#INFO#' then begin
          CmpWnd.SetTextLine('Info');
          NewHint := TRHint.Create(etInfo);
          VReadLn(sTmp);
          NewHint.OwnRef := StrToInt(DecodeLine(sTmp,Author));
          VReadLn(sTmp);
          NewHint.sText := DecodeLine(sTmp,Author);
          VReadLn(sTmp);
          if DecodeLine(sTmp,Author) = '#TEXT#' then begin
            VReadLn(sTmp);
            sTmp := DecodeLine(sTmp,Author);
            while (sTmp <> '#FINISH#') do begin
              NewHint.HintText.Add(sTmp);
              VReadLn(sTmp);
              sTmp := DecodeLine(sTmp,Author);
            end;
            if FileVer > 100 then begin
              VReadLn(sTmp);
              if DecodeLine(sTmp,Title) = '#LINKS#' then begin
                VReadLn(sTmp);
                sTmp := DecodeLine(sTmp,Title);
                ECount := StrToInt(sTmp);
                for l:=1 to ECount do begin
                  LinkEntry := TNodeLink.Create;
                  VReadLn(sTmp);
                  LinkEntry.sDescription := DecodeLine(sTmp,Title);
                  VReadLn(sTmp);
                  LinkEntry.iNodeIdx := StrToInt(DecodeLine(sTmp,Title));
                  NewHint.Links.Add(LinkEntry);
                end;
              end
              else begin
                LDMessageDlg(Messages[2],mtError,[mbOK],0);
                bRet := False;
              end;
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
          if FileVer > 100 then begin
            VReadLn(sTmp);
            if DecodeLine(sTmp,Title) = '#LINKS#' then begin
              VReadLn(sTmp);
              sTmp := DecodeLine(sTmp,Title);
              ECount := StrToInt(sTmp);
              for l:=1 to ECount do begin
                LinkEntry := TNodeLink.Create;
                VReadLn(sTmp);
                LinkEntry.sDescription := DecodeLine(sTmp,Title);
                VReadLn(sTmp);
                LinkEntry.iNodeIdx := StrToInt(DecodeLine(sTmp,Title));
                NewHint.Links.Add(LinkEntry);
              end;
            end
            else begin
              LDMessageDlg(Messages[2],mtError,[mbOK],0);
              bRet := False;
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
          else begin
            if FileVer > 100 then begin
              VReadLn(sTmp);
              if DecodeLine(sTmp,Title) = '#LINKS#' then begin
                VReadLn(sTmp);
                sTmp := DecodeLine(sTmp,Title);
                ECount := StrToInt(sTmp);
                for l:=1 to ECount do begin
                  LinkEntry := TNodeLink.Create;
                  VReadLn(sTmp);
                  LinkEntry.sDescription := DecodeLine(sTmp,Title);
                  VReadLn(sTmp);
                  LinkEntry.iNodeIdx := StrToInt(DecodeLine(sTmp,Title));
                  NewHint.Links.Add(LinkEntry);
                end;
              end
              else begin
                LDMessageDlg(Messages[2],mtError,[mbOK],0);
                bRet := False;
              end;
            end;
            MainList.Add(NewHint);
          end;
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
  InfoCapLine := '';
  InfoWndLine := '';
  Zusatz := TStringList.Create;
  TopicCombo.Enabled := False;
end;

procedure TReaderForm.FormDestroy(Sender: TObject);
begin
  Zusatz.Free;
end;

procedure TReaderForm.BitBtn1Click(Sender: TObject);
begin
  InfoWindow.Close;
  HintWindow.Close;
  MMWnd.Close;
  ShowPic.Close;
  Close;
end;

procedure TReaderForm.SetInfos;
Var bSized      : Boolean;
    TmpRect     : TRect;
    TitleHeight : Integer;
begin
  TitleBox.Caption := Title;
  Refresh;
  if Zusatz.Count > 0 then
    ZusatzMemo.Lines := Zusatz;
  ZusatzMemo.Lines.Insert(0,Author);
  Refresh;
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
                    CurrList.Add( HintToken + ' '+IntToStr(iHintCnt));
                    IndexList.Add(IntToStr(i));
                  end;
        etInfo  : begin
                    if OneHint.sText <> '' then
                      CurrList.Add(OneHint.sText)
                    else
                      CurrList.Add( 'Information' );
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
{    OneHint := MainList.Items[ StrToInt(IndexList[1]) ];
    IndexList.Add(IntToStr(OneHint.OwnRef));}
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
    Links   : TList;
begin
  TopicCombo.Enabled := False;
  UniLister.Hint := '';
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
    etTopic : begin
                FillListAndIndex(i);
              end;
    etHint  : begin
                wRes := mrYes;
                if not HintsRead then
                  wRes := LDMessageDlg(Messages[3],mtConfirmation,[mbYES,mbNO],0);
                if wRes = mrYes then begin
                  HintWindow.HintMemo.Lines := TheHint.HintText;
                  HintWindow.ShowForm(TheHint.Links);
                  HintBools[UniLister.ItemIndex] := True;
                end;
              end;
    etInfo  : begin
                if TheHint.sText = '' then
                  InfoWindow.Caption := 'Information'
                else
                  InfoWindow.Caption := TheHint.sText;
                InfoWindow.InfoMemo.Lines := TheHint.HintText;
                InfoWindow.ShowForm(TheHint.Links);
              end;
    etPic   : begin
                ShowPic.WindowState := wsNormal;
                ShowPic.ShowForm(TheHint.Links);
                ShowPic.SetPicture(TheHint.Filename,
                                   TheHint.GetRectFromDesc(
                                   UniLister.Items[UniLister.ItemIndex]));
              end;
    etMM    : begin
                MMWnd.Label1.Caption := TheHint.sText;
                MMWnd.MediaPlayer1.Filename := TheHint.Filename;
                MMWnd.MediaPlayer1.Open;
                MMWnd.ShowForm(TheHint.Links);
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
  Offset   : Integer;	{ Abstand zum Text }  TheHint  : TRHint;  i        : Integer;  TheIcon  : TIcon;  sTmp     : String;  TmpRect  : TRect;begin  with (Control as TListBox).Canvas do	{ Zeichnen auf der Zeichenfläche des }	{ Dialogelements, nicht auf dem Formular }  begin    FillRect(Rect);	{ Rechteck löschen }

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
      etInfo  : TheIcon := InfoImg.Picture.Icon;
      end;
    end;
    Draw(Rect.Left + 2, Rect.Top+4,TheIcon);

    Offset := TheIcon.width + 6;{ Vier Pixel zwischen Text und Icon hinzufügen }
    sTmp := UniLister.Items[Index];
    TmpRect.Left := Rect.Left+Offset;
    TmpRect.Top := Rect.Top+5;
    TmpRect.Right := Rect.Right;
    TmpRect.Bottom := Rect.Bottom;
    DrawText(Handle,PChar(sTmp),Length(sTmp),
             TmpRect,(DT_WORDBREAK or DT_LEFT or DT_NOPREFIX) );	{ Text anzeigen }
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
  LoadString(HL,307,Buffer,sizeof(Buffer));
  InfoCapLine := StrPas(Buffer);
  LoadString(HL,308,Buffer,sizeof(Buffer));
  InfoWndLine := StrPas(Buffer);
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
Var bSized      : Boolean;
    TmpRect     : TRect;    
    TitleHeight : Integer;
begin
  if Height < 386 then Height := 386;
  if Width < 479 then Width := 479;
  TitleBox.Width := ReaderForm.ClientWidth-16;
  UniLister.Width := ReaderForm.ClientWidth-16;
  ZusatzMemo.Width := ReaderForm.ClientWidth-16;
  BitBtn1.Left := (ReaderForm.ClientWidth-BitBtn1.Width -16);
  BitBtn1.Top := ReaderForm.ClientHeight-40;
  TopicCombo.Top := ReaderForm.ClientHeight-40;
  ZusatzMemo.Top := ReaderForm.ClientHeight-120;
  UniLister.Height := ClientHeight-UniLister.Top-130;
end;

procedure TReaderForm.UniListerClick(Sender: TObject);
Var i       : Integer;
    TheHint : TRHint;
begin
  UniLister.Hint := UniLister.Items[UniLister.ItemIndex];
  i:=StrToInt(IndexList[UniLister.ItemIndex+1]);
  if UniLister.Items[UniLister.ItemIndex] <> BackToken then begin
    TheHint := TRHint(MainList.Items[i]);
    if TheHint.Rtype = etTopic then begin
      TopicLinks := TheHint.Links;
      FillComboBox;
    end
    else
      TopicCombo.Enabled := False;
  end;
end;

procedure TReaderForm.UniListerMeasureItem(Control: TWinControl;
  Index: Integer; var Height: Integer);
Var Offset    : Integer;
    sTmp      : String;
    TmpRect   : TRect;
    StrHeight : Integer;
begin
  with control as TListBox do
  begin
    Offset := TopicImg.width + 6;{ Vier Pixel zwischen Text und Icon hinzufügen }
    sTmp := UniLister.Items[Index];
    TmpRect.Left := Offset;
    TmpRect.Top := 5;
    TmpRect.Right := Width;
    TmpRect.Bottom := 6;
    StrHeight := DrawTextEx(Canvas.Handle,PChar(sTmp),-1,
                 TmpRect,(DT_LEFT or DT_CALCRECT or DT_WORDBREAK or
                 DT_NOPREFIX),nil );
  end;
  if StrHeight >= (TopicImg.Height+4) then
    Height := StrHeight
  else
    Height := (TopicImg.Height+4);
end;

procedure TReaderForm.ParseLinkRequest( iIndex : Integer );
Var TheHint : TRHint;
begin
  TheHint := MainList.Items[iIndex];
  case TheHint.RType of
  etTopic : begin
              FillListAndIndex(iIndex);
              BringToFront;
            end;
  etHint  : begin
              HintWindow.HintMemo.Lines := TheHint.HintText;
              HintWindow.ShowForm(TheHint.Links);
            end;
  etInfo  : begin
              if TheHint.sText = '' then
                InfoWindow.Caption := 'Information'
              else
                InfoWindow.Caption := TheHint.sText;
              InfoWindow.InfoMemo.Lines := TheHint.HintText;
              InfoWindow.ShowForm(TheHint.Links);
            end;
  etPic   : begin
              ShowPic.WindowState := wsNormal;
              ShowPic.ShowForm(TheHint.Links);
              ShowPic.SetPicture(TheHint.Filename,
                                 TheHint.GetRectFromDesc(
                                 '~~~$$$###ALL###$$$~~~'));
            end;
  etMM    : begin
              MMWnd.Label1.Caption := TheHint.sText;
              MMWnd.MediaPlayer1.Filename := TheHint.Filename;
              MMWnd.MediaPlayer1.Open;
              MMWnd.ShowForm(TheHint.Links);
            end;
  end;
end;

procedure TReaderForm.FillComboBox;
Var i       : Integer;
    OneNode : TNodeLink;
begin
  TopicCombo.Items.Clear;
  if TopicLinks.Count > 0 then begin
    for i:=0 to TopicLinks.Count-1 do begin
      OneNode := TNodeLink(TopicLinks.Items[i]);
      TopicCombo.Items.Add(OneNode.sDescription);
    end;
    TopicCombo.Enabled := True;
  end
  else
    TopicCombo.Enabled := False;
end;

procedure TReaderForm.TopicComboChange(Sender: TObject);
Var SelNode : TNodeLink;
begin
  SelNode := TNodeLink(TopicLinks.Items[TopicCombo.ItemIndex]);
  ParseLinkRequest(SelNode.iNodeIdx);
end;

end.
