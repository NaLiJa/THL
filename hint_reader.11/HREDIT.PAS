unit hredit;

{ LANG TEXT RANGE: 500-514;516-527;530-537;540-544 }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ComCtrls, Main, Gauges, Menus, LinkWnd;

type
  THREditor = class(TForm)
    TreeView1: TTreeView;
    GroupBox1: TGroupBox;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    GroupBox2: TGroupBox;
    BitBtn7: TBitBtn;
    BitBtn8: TBitBtn;
    Edit1: TEdit;
    Label1: TLabel;
    Edit2: TEdit;
    Label2: TLabel;
    Memo1: TMemo;
    Label3: TLabel;
    SaveDialog1: TSaveDialog;
    OpenEdit: TOpenDialog;
    Button1: TButton;
    FontDialog1: TFontDialog;
    BitBtn6: TBitBtn;
    BitBtn9: TBitBtn;
    BitBtn10: TBitBtn;
    BitBtn11: TBitBtn;
    ProgressInd: TGauge;
    EditorMenu1: TMainMenu;
    Datei1: TMenuItem;
    compiler1: TMenuItem;
    ffnen1: TMenuItem;
    N1: TMenuItem;
    Speichern1: TMenuItem;
    Speichernals1: TMenuItem;
    N2: TMenuItem;
    Shlieen1: TMenuItem;
    bersetzen2: TMenuItem;
    bersetzenals1: TMenuItem;
    EditorClipMenu: TPopupMenu;
    NeuesThema1: TMenuItem;
    NeuerHinweis1: TMenuItem;
    NeuerBildeintrag1: TMenuItem;
    NeueMediendatei1: TMenuItem;
    NeueInformation1: TMenuItem;
    BitBtn1: TBitBtn;
    BitBtn4: TBitBtn;
    Neu1: TMenuItem;
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn6Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn8Click(Sender: TObject);
    procedure BitBtn7Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure BitBtn5Click(Sender: TObject);
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
    procedure BitBtn9Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BitBtn10Click(Sender: TObject);
    procedure BitBtn11Click(Sender: TObject);
    procedure Shlieen1Click(Sender: TObject);
    procedure ffnen1Click(Sender: TObject);
    procedure Speichern1Click(Sender: TObject);
    procedure bersetzen2Click(Sender: TObject);
    procedure Speichernals1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Kopieren1Click(Sender: TObject);
    procedure Einfgen1Click(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
    procedure TreeView1DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure TreeView1DragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure Neu1Click(Sender: TObject);
  private
    Messages : array[1..10] of string;
    CurrFilename : string;
    MoveNodeID   : Integer;
    procedure RebuildLinks( CList : TStringList );
    { Private-Deklarationen }
  public
    procedure Initialise;
    procedure OpenExistFile( TheFile : string );
    function EncodeLine( Src, Passwd : string ):string;
    procedure SetLanguage( HL : THandle );
    procedure ReadTHR_110( TheFile : string );
    procedure SaveTHR_110( TheFile : string );
    procedure CompileTHL_110( TheFile : string );
    procedure ShowForm;
    { Public-Deklarationen }
  end;

const DEF_ROOT = '<<< Script >>>';

var
  HREditor  : THREditor;

implementation

uses CompWnd,LDMsgDlg;

{$R *.DFM}

procedure THREditor.BitBtn2Click(Sender: TObject);
Var NewHT    : THEntry;
    NewNode  : TTreeNode;
    Owner    : THEntry;
    etEnter  : EntryType;
begin
  etEnter := etTopic;
  if TreeView1.Selected.Text <> DEF_ROOT then begin
    Owner := TreeView1.Selected.Data;
    etEnter := Owner.HType;
  end;
  if etEnter = etTopic then begin
    NewHT := THEntry.Create(etTopic);
    NewHT.GetAndSetEntry;
    if NewHT.IsValid then begin
      NewNode := TreeView1.Items.AddChild( TreeView1.Selected,NewHT.GetText);
      NewNode.Data := NewHT;
      TreeView1.Selected.Expand(False);
{      TreeView1.FullExpand; }
      TreeView1Change(Sender, TreeView1.Selected);
      TreeView1.SetFocus;
    end
    else
      NewHT.Free;
  end
  else
    LDMessageDlg(Messages[1],mtError,[mbOK],0);
end;

procedure THREditor.BitBtn6Click(Sender: TObject);
Var NewHT    : THEntry;
    NewNode  : TTreeNode;
    Owner    : THEntry;
    etEnter  : EntryType;
begin
  etEnter := etTopic;
  if TreeView1.Selected.Text <> DEF_ROOT then begin
    Owner := TreeView1.Selected.Data;
    etEnter := Owner.HType;
  end;
  if etEnter = etTopic then begin
    NewHT := THEntry.Create(etPic);
    NewHT.GetAndSetEntry;
    if NewHT.IsValid then begin
      NewNode := TreeView1.Items.AddChild( TreeView1.Selected,NewHT.GetText);
      NewNode.Data := NewHT;
      TreeView1.Selected.Expand(False);
{      TreeView1.FullExpand;}
      TreeView1Change(Sender, TreeView1.Selected);
      TreeView1.Selected.Focused := True;
    end
    else
      NewHT.Free;
  end
  else
    LDMessageDlg(Messages[1],mtError,[mbOK],0);
end;

procedure THREditor.BitBtn3Click(Sender: TObject);
Var NewHT    : THEntry;
    NewNode  : TTreeNode;
    Owner    : THEntry;
    etEnter  : EntryType;
begin
  etEnter := etTopic;
  if TreeView1.Selected.Text <> DEF_ROOT then begin
    Owner := TreeView1.Selected.Data;
    etEnter := Owner.HType;
  end;
  if etEnter = etTopic then begin
    NewHT := THEntry.Create(etHint);
    NewHT.GetAndSetEntry;
    if NewHT.IsValid then begin
      NewNode := TreeView1.Items.AddChild( TreeView1.Selected,NewHT.GetText);
      NewNode.Data := NewHT;
      TreeView1.Selected.Expand(False);
{      TreeView1.FullExpand;}
      TreeView1Change(Sender, TreeView1.Selected);
      TreeView1.Selected.Focused := True;
    end
    else
      NewHT.Free;
  end
  else
    LDMessageDlg(Messages[1],mtError,[mbOK],0);
end;

procedure THREditor.BitBtn1Click(Sender: TObject);
Var NewHT    : THEntry;
    NewNode  : TTreeNode;
    Owner    : THEntry;
    etEnter  : EntryType;
begin
  etEnter := etTopic;
  if TreeView1.Selected.Text <> DEF_ROOT then begin
    Owner := TreeView1.Selected.Data;
    etEnter := Owner.HType;
  end;
  if etEnter = etTopic then begin
    NewHT := THEntry.Create(etInfo);
    NewHT.GetAndSetEntry;
    if NewHT.IsValid then begin
      NewNode := TreeView1.Items.AddChild( TreeView1.Selected,NewHT.GetText);
      NewNode.Data := NewHT;
      TreeView1.Selected.Expand(False);
      TreeView1Change(Sender, TreeView1.Selected);
      TreeView1.Selected.Focused := True;
    end
    else
      NewHT.Free;
  end
  else
    LDMessageDlg(Messages[1],mtError,[mbOK],0);
end;

procedure THREditor.BitBtn8Click(Sender: TObject);
Var wRes     : Word;
    Owner    : THEntry;
begin
  if TreeView1.Selected.Text <> DEF_ROOT then begin
    wRes := LDMessageDlg(TreeView1.Selected.Text+#13+Messages[3],
                        mtConfirmation,[mbYES,mbNO],0);
    if wRes = mrYES then begin
      Owner := TreeView1.Selected.Data;
      Owner.DeleteEntry;
      TreeView1.Selected.Delete;
    end;
  end
  else
    LDMessageDlg(Messages[4], mtInformation, [mbOK],0);
end;

procedure THREditor.BitBtn7Click(Sender: TObject);
Var Owner    : THEntry;
begin
  if TreeView1.Selected.Text <> DEF_ROOT then begin
    Owner := TreeView1.Selected.Data;
    Owner.EditEntry;
    TreeView1.Selected.Text := Owner.GetText;
  end;
end;

procedure THREditor.OpenExistFile( TheFile : string);
begin
  if TheFile = '' then begin
    if OpenEdit.Execute then
      TheFile := OpenEdit.Filename;
  end;
  if TheFile <> '' then begin
    Initialise;
    ReadTHR_110( TheFile );
  end;  
  TreeView1.Items[0].Expand(False);
end;

procedure THREditor.Initialise;
begin
  Edit1.Text := '';
  Edit2.Text := '';
{  ComboBox1.ItemIndex := -1;}
  Memo1.Lines.Clear;
  TreeView1.Items.Clear;
  TreeView1.Items.AddChild(nil,DEF_ROOT);
  TreeView1.Selected := TreeView1.Items[0];
  CurrFilename := '';
  Openedit.InitialDir := ExtractFilePath(Application.Exename)+'thlfiles';
end;

procedure THREditor.Button1Click(Sender: TObject);
begin
  FontDialog1.Execute;
end;

function THREditor.EncodeLine( Src,Passwd : string ):string;
Var EChar     : Char;
    i,ec      : Integer;
    Encrypted : string;
    Checksum  : longint;
begin

  ec := 1;
  for i:=1 to Length(Src) do begin
    EChar := Passwd[ec];
    Encrypted := Encrypted + Chr( ord(Src[i]) + ord(EChar) );
    ec := (ec+1) mod Length(Passwd);
  end;
  EncodeLine := Encrypted;

end;

procedure THREditor.BitBtn5Click(Sender: TObject);
begin
  if (Edit1.Text = '') or (Edit2.Text = '')  then
    LDMessageDlg(Messages[2], mtError,[mbOK],0)
  else begin
    SaveDialog1.Filename := '';
    SaveDialog1.FilterIndex := 2;
    if SaveDialog1.Execute then begin
      CompileTHL_110(SaveDialog1.Filename);
    end;
  end;
end;

procedure THREditor.SetLanguage( HL : THandle );
Var Buffer : array[0..254] of char;
begin
  LoadString(HL,500,Buffer,sizeof(Buffer));
  HREditor.Caption := StrPas(Buffer);
  LoadString(HL,501,Buffer,sizeof(Buffer));
  HREditor.Groupbox1.Caption := StrPas(Buffer);
  LoadString(HL,502,Buffer,sizeof(Buffer));
  HREditor.Groupbox2.Caption := StrPas(Buffer);
  LoadString(HL,503,Buffer,sizeof(Buffer));
  HREditor.Label1.Caption := StrPas(Buffer);
  LoadString(HL,504,Buffer,sizeof(Buffer));
  HREditor.Label2.Caption := StrPas(Buffer);
  LoadString(HL,505,Buffer,sizeof(Buffer));
  HREditor.Label3.Caption := StrPas(Buffer);
  LoadString(HL,506,Buffer,sizeof(Buffer));
  HREditor.Button1.Caption := StrPas(Buffer);
  LoadString(HL,507,Buffer,sizeof(Buffer));
  HREditor.BitBtn2.Caption := StrPas(Buffer);
  LoadString(HL,508,Buffer,sizeof(Buffer));
  HREditor.BitBtn3.Caption := StrPas(Buffer);
  LoadString(HL,509,Buffer,sizeof(Buffer));
  HREditor.BitBtn6.Caption := StrPas(Buffer);
  LoadString(HL,510,Buffer,sizeof(Buffer));
  HREditor.BitBtn9.Caption := StrPas(Buffer);
  LoadString(HL,511,Buffer,sizeof(Buffer));
  HREditor.BitBtn7.Caption := StrPas(Buffer);
  LoadString(HL,512,Buffer,sizeof(Buffer));
  HREditor.BitBtn8.Caption := StrPas(Buffer);
  LoadString(HL,513,Buffer,sizeof(Buffer));
  HREditor.BitBtn1.Caption := StrPas(Buffer);
  LoadString(HL,514,Buffer,sizeof(Buffer));
  HREditor.BitBtn4.Caption := StrPas(Buffer);
  LoadString(HL,516,Buffer,sizeof(Buffer));
  HREditor.BitBtn10.Caption := StrPas(Buffer);
  LoadString(HL,517,Buffer,sizeof(Buffer));
  HREditor.BitBtn11.Caption := StrPas(Buffer);
  LoadString(HL,518,Buffer,sizeof(Buffer));
  Messages[1] := StrPas(Buffer);
  LoadString(HL,519,Buffer,sizeof(Buffer));
  Messages[2] := StrPas(Buffer);
  LoadString(HL,520,Buffer,sizeof(Buffer));
  Messages[3] := StrPas(Buffer);
  LoadString(HL,521,Buffer,sizeof(Buffer));
  Messages[4] := StrPas(Buffer);
  LoadString(HL,522,Buffer,sizeof(Buffer));
  Messages[5] := StrPas(Buffer);
  LoadString(HL,523,Buffer,sizeof(Buffer));
  Messages[6] := StrPas(Buffer);
  LoadString(HL,524,Buffer,sizeof(Buffer));
  Messages[7] := StrPas(Buffer);
  LoadString(HL,525,Buffer,sizeof(Buffer));
  Messages[8] := StrPas(Buffer);
  LoadString(HL,526,Buffer,sizeof(Buffer));
  Messages[9] := StrPas(Buffer);
  LoadString(HL,527,Buffer,sizeof(Buffer));
  Messages[10] := StrPas(Buffer);
  LoadString(HL,530,Buffer,sizeof(Buffer));
  Datei1.Caption := StrPas(Buffer);
  LoadString(HL,531,Buffer,sizeof(Buffer));
  ffnen1.Caption := StrPas(Buffer);
  LoadString(HL,532,Buffer,sizeof(Buffer));
  Speichern1.Caption := StrPas(Buffer);
  LoadString(HL,533,Buffer,sizeof(Buffer));
  Speichernals1.Caption := StrPas(Buffer);
  LoadString(HL,534,Buffer,sizeof(Buffer));
  Shlieen1.Caption:= StrPas(Buffer);
  LoadString(HL,535,Buffer,sizeof(Buffer));
  Compiler1.Caption := StrPas(Buffer);
  LoadString(HL,536,Buffer,sizeof(Buffer));
  bersetzen2.Caption := StrPas(Buffer);
  LoadString(HL,537,Buffer,sizeof(Buffer));
  bersetzenals1.Caption := StrPas(Buffer);
  LoadString(HL,538,Buffer,sizeof(Buffer));
  Neu1.Caption := StrPas(Buffer);
  LoadString(HL,540,Buffer,sizeof(Buffer));
  EditorClipMenu.Items[0].Caption := StrPas(Buffer);
  LoadString(HL,541,Buffer,sizeof(Buffer));
  EditorClipMenu.Items[2].Caption := StrPas(Buffer);
  LoadString(HL,542,Buffer,sizeof(Buffer));
  EditorClipMenu.Items[1].Caption := StrPas(Buffer);
  LoadString(HL,543,Buffer,sizeof(Buffer));
  EditorClipMenu.Items[3].Caption := StrPas(Buffer);
  LoadString(HL,544,Buffer,sizeof(Buffer));
  EditorClipMenu.Items[4].Caption := StrPas(Buffer);
end;

procedure THREditor.TreeView1Change(Sender: TObject; Node: TTreeNode);
Var i        : Integer;
    Owner    : THEntry;
begin
  if Node.Text = DEF_ROOT then begin
    HREditor.BitBtn2.Enabled := True;
    EditorClipMenu.Items[0].Enabled := True;
    HREditor.BitBtn3.Enabled := True;
    EditorClipMenu.Items[1].Enabled := True;
    HREditor.BitBtn6.Enabled := True;
    EditorClipMenu.Items[2].Enabled := True;
    HREditor.BitBtn9.Enabled := True;
    EditorClipMenu.Items[3].Enabled := True;
    HREditor.BitBtn1.Enabled := True;
    EditorClipMenu.Items[4].Enabled := True;
    BitBtn4.Enabled := False;
    BitBtn7.Enabled := False;
    BitBtn8.Enabled := False;
    BitBtn10.Enabled := False;
    BitBtn11.Enabled := False;
  end
  else begin
    BitBtn7.Enabled := True;
    BitBtn8.Enabled := True;
    BitBtn4.Enabled := True;
    if Node.Index = 0 then
      BitBtn10.Enabled := False
    else
      BitBtn10.Enabled := True;
    if Node.Index = Node.Parent.Count-1 then
      BitBtn11.Enabled := False
    else
      BitBtn11.Enabled := True;
    Owner := Node.Data;
    if ((Owner.HType = etHint) or (Owner.HType = etPic) or
        (Owner.HType = etMM)  or (Owner.HType = etInfo) ) then begin
      HREditor.BitBtn1.Enabled := False;
      HREditor.BitBtn2.Enabled := False;
      HREditor.BitBtn3.Enabled := False;
      HREditor.BitBtn6.Enabled := False;
      HREditor.BitBtn9.Enabled := False;
      EditorClipMenu.Items[0].Enabled := False;
      EditorClipMenu.Items[1].Enabled := False;
      EditorClipMenu.Items[2].Enabled := False;
      EditorClipMenu.Items[3].Enabled := False;
      EditorClipMenu.Items[4].Enabled := False;
    end
    else begin
      HREditor.BitBtn1.Enabled := True;
      HREditor.BitBtn2.Enabled := True;
      HREditor.BitBtn3.Enabled := True;
      HREditor.BitBtn6.Enabled := True;
      HREditor.BitBtn9.Enabled := True;
      EditorClipMenu.Items[0].Enabled := True;
      EditorClipMenu.Items[1].Enabled := True;
      EditorClipMenu.Items[2].Enabled := True;
      EditorClipMenu.Items[3].Enabled := True;
      EditorClipMenu.Items[4].Enabled := True;
    end;
  end;
end;

procedure THREditor.BitBtn9Click(Sender: TObject);
Var NewHT    : THEntry;
    NewNode  : TTreeNode;
    Owner    : THEntry;
    etEnter  : EntryType;
begin
  etEnter := etTopic;
  if TreeView1.Selected.Text <> DEF_ROOT then begin
    Owner := TreeView1.Selected.Data;
    etEnter := Owner.HType;
  end;
  if etEnter <> etHint then begin
    NewHT := THEntry.Create(etMM);
    NewHT.GetAndSetEntry;
    if NewHT.IsValid then begin
      NewNode := TreeView1.Items.AddChild( TreeView1.Selected,NewHT.GetText);
      NewNode.Data := NewHT;
      TreeView1.FullExpand;
      TreeView1Change(Sender, TreeView1.Selected);
      TreeView1.SetFocus;
    end
    else
      NewHT.Free;
  end
  else
    LDMessageDlg(Messages[1],mtError,[mbOK],0);
end;

procedure THREditor.FormCreate(Sender: TObject);
begin
  Initialise;
  TreeView1.Selected := TreeView1.Items[0];
  TreeView1.Selected.Focused := True;
  CurrFilename := '';
  MoveNodeID := -1;
  
end;

procedure THREditor.BitBtn10Click(Sender: TObject);
begin
  TreeView1.Selected.MoveTo(
        TreeView1.Selected.Parent.Item[TreeView1.Selected.Index-1] ,naInsert);
  TreeView1.Selected.Parent.Expand(False);
{  TreeView1.FullExpand;}
  TreeView1Change(Sender, TreeView1.Selected);
  TreeView1.Selected.Focused := True;
  TreeView1.SetFocus;
end;

procedure THREditor.BitBtn11Click(Sender: TObject);
begin
  TreeView1.Selected := TreeView1.Selected.GetNextSibling;
  TreeView1.Selected.MoveTo(
        TreeView1.Selected.Parent.Item[TreeView1.Selected.Index-1] ,naInsert);
  TreeView1.Selected.Parent.Expand(False);
{  TreeView1.FullExpand;}
  TreeView1Change(Sender, TreeView1.Selected);
  TreeView1.Selected.Focused := True;
  TreeView1.SetFocus;
  TreeView1.Selected := TreeView1.Selected.GetNextSibling;
end;

procedure THREditor.Shlieen1Click(Sender: TObject);
begin
  HREditor.Close;
end;

procedure THREditor.ffnen1Click(Sender: TObject);
begin
  OpenExistFile('');
end;

procedure THREditor.ReadTHR_110( TheFile : string );
Var F          : TextFile;
    sTmp       : String;
    sTmp2      : String;
    NewNode    : TTreeNode;
    NewEntry   : THEntry;
    i,j        : Integer;
    ExtLoad    : Boolean;
    wAnswer    : Word;
    lLastPar   : longint;
    LastNode   : TTreeNode;
    TmpLink    : TNodeLink;
    FileVer    : Integer;
    CacheList  : TStringList;
begin
  if TheFile <> '' then begin
  try
    AssignFile(F,TheFile);
    Reset(F);
    CurrFilename := TheFile;
    { ...Daten lesen ! }
    { Version }
    ReadLn(F,sTmp);
    FileVer := StrToInt(sTmp);
    if FileVer > StrToInt(PRG_VER) then
      LDMessageDlg(Messages[5], mtError,[mbOK],0)
    else begin
    { Titel }
    ReadLn(F,sTmp);
    Edit1.Text := sTmp;
    { Schrift }
    ReadLn(F,sTmp);
    FontDialog1.Font.Name := sTmp;
    ReadLn(F,sTmp);
    FontDialog1.Font.Color := StrToInt(sTmp);
    ReadLn(F,sTmp);
    FontDialog1.Font.Size := StrToInt(sTmp);
    ReadLn(F,sTmp);
    FontDialog1.Font.Style := [];
    if sTmp[1] = '1' then
      FontDialog1.Font.Style := FontDialog1.Font.Style + [fsBold];
    if sTmp[2] = '1' then
      FontDialog1.Font.Style := FontDialog1.Font.Style + [fsItalic];
    if sTmp[3] = '1' then
      FontDialog1.Font.Style := FontDialog1.Font.Style + [fsUnderline];
    if sTmp[4] = '1' then
      FontDialog1.Font.Style := FontDialog1.Font.Style + [fsStrikeOut];
    { Autor }
    ReadLn(F,sTmp);
    Edit2.Text := sTmp;
    { Notiz }
    ReadLn(F,sTmp);
    if sTmp = '#NOTICE<#' then begin
      ReadLn(F,sTmp);
      while sTmp <> '#>NOTICE#' do begin
        Memo1.Lines.Add(sTmp);
        ReadLn(F,sTmp);
      end;
      { Hints }
      lLastPar := -777;
      LastNode := nil;
      CacheList := TStringList.Create;
      while not eof(F) do begin
        ReadLn(F,sTmp);
        if sTmp = '#MM#' then begin
          NewEntry := THEntry.Create(etMM);
          ReadLn(F,sTmp);
          ReadLn(F,sTmp2);
          NewEntry.sEntries.sComplex.Add(sTmp2);
          ReadLn(F,sTmp2);
          NewEntry.sEntries.sComplex.Add(sTmp2);
          if FileVer > 100 then begin
            ReadLn(F,sTmp2);
            if sTmp2 <> '#LINKS#' then begin
              LDMessageDlg(Messages[6]+' #LINKS#',mtWarning,[mbOK],0);
              break;
            end;
            ReadLn(F,sTmp2);
            for j:= 1 to StrToInt(sTmp2) do begin
              TmpLink := TNodeLink.Create;
              ReadLn(F,sTmp2);
              TmpLink.sDescription := sTmp2;
              ReadLn(F,sTmp2);
              TmpLink.iNodeIdx := StrToInt(sTmp2);
              NewEntry.LinkList.Add(TmpLink);
            end;
          end;
          if not FileExists(NewEntry.sEntries.sComplex[1]) then
            LDMessageDlg(NewEntry.sEntries.sComplex[1]+#13+Messages[9],
                       mtWarning,[mbOK],0);
          if StrToInt(sTmp)=lLastPar then
            NewNode := TreeView1.Items.AddChild( LastNode,NewEntry.GetText)
          else begin
            lLastPar := StrToInt(sTmp);
            LastNode := TreeView1.Items[lLastPar];
            NewNode := TreeView1.Items.AddChild(LastNode,NewEntry.GetText);
          end;
          if NewEntry.LinkList.Count > 0 then
            CacheList.Add(IntToStr(TreeView1.Items.Count));
          NewNode.Data := NewEntry;
          {TreeView1.FullExpand;}
        end;
        if sTmp = '#PIC#' then begin
          NewEntry := THEntry.Create(etPic);
          ReadLn(F,sTmp);
          ReadLn(F,sTmp2);
          NewEntry.sEntries.sSimple := sTmp2;
          ReadLn(F,sTmp2);
          for i := 1 to StrToInt(sTmp2) do begin
            ReadLn(F,sTmp2);
            NewEntry.sEntries.sComplex.Add(sTmp2);
            ReadLn(F,sTmp2);
            NewEntry.sEntries.sComplex2.Add(sTmp2);
          end;
          if FileVer > 100 then begin
            ReadLn(F,sTmp2);
            if sTmp2 <> '#LINKS#' then begin
              LDMessageDlg(Messages[6]+' #LINKS#',mtWarning,[mbOK],0);
              break;
            end;
            ReadLn(F,sTmp2);
            for j:= 1 to StrToInt(sTmp2) do begin
              TmpLink := TNodeLink.Create;
              ReadLn(F,sTmp2);
              TmpLink.sDescription := sTmp2;
              ReadLn(F,sTmp2);
              TmpLink.iNodeIdx := StrToInt(sTmp2);
              NewEntry.LinkList.Add(TmpLink);
            end;
          end;
          if not FileExists(NewEntry.sEntries.sSimple) then
            LDMessageDlg(NewEntry.sEntries.sSimple+#13+Messages[9],
                       mtWarning,[mbOK],0);
          if StrToInt(sTmp)=lLastPar then
            NewNode := TreeView1.Items.AddChild( LastNode,NewEntry.GetText)
          else begin
            lLastPar := StrToInt(sTmp);
            LastNode := TreeView1.Items[lLastPar];
            NewNode := TreeView1.Items.AddChild(LastNode,NewEntry.GetText);
          end;
          if NewEntry.LinkList.Count > 0 then
            CacheList.Add(IntToStr(TreeView1.Items.Count));
          NewNode.Data := NewEntry;
{          TreeView1.FullExpand;}
        end;
        if sTmp = '#TOPIC#' then begin
          NewEntry := THEntry.Create(etTopic);
          ReadLn(F,sTmp);
          ReadLn(F,sTmp2);
          NewEntry.sEntries.sSimple := sTmp2;
          if FileVer > 100 then begin
            ReadLn(F,sTmp2);
            if sTmp2 <> '#LINKS#' then begin
              LDMessageDlg(Messages[6]+' #LINKS#',mtWarning,[mbOK],0);
              break;
            end;
            ReadLn(F,sTmp2);
            for j:= 1 to StrToInt(sTmp2) do begin
              TmpLink := TNodeLink.Create;
              ReadLn(F,sTmp2);
              TmpLink.sDescription := sTmp2;
              ReadLn(F,sTmp2);
              TmpLink.iNodeIdx := StrToInt(sTmp2);
              NewEntry.LinkList.Add(TmpLink);
            end;
          end;
          if StrToInt(sTmp)=lLastPar then
            NewNode := TreeView1.Items.AddChild( LastNode,NewEntry.GetText)
          else begin
            lLastPar := StrToInt(sTmp);
            LastNode := TreeView1.Items[lLastPar];
            NewNode := TreeView1.Items.AddChild(LastNode,NewEntry.GetText);
          end;
          if NewEntry.LinkList.Count > 0 then
            CacheList.Add(IntToStr(TreeView1.Items.Count));
          NewNode.Data := NewEntry;
{          TreeView1.FullExpand;}
        end;
        if sTmp = '#INFO#' then begin
          NewEntry := THEntry.Create(etInfo);
          ReadLn(F,sTmp);
          ReadLn(F,sTmp2);
          NewEntry.sEntries.sSimple := sTmp2;
          ReadLn(F,sTmp2);
          if sTmp2 <> '#TEXT#' then begin
            LDMessageDlg(Messages[6]+' #TEXT#',mtWarning,[mbOK],0);
            break;
          end;
          ReadLn(F,sTmp2);
          while sTmp2 <> '#FINISH#' do begin
            NewEntry.sEntries.sComplex.Add(sTmp2);
            ReadLn(F,sTmp2);
          end;
          if FileVer > 100 then begin
            ReadLn(F,sTmp2);
            if sTmp2 <> '#LINKS#' then begin
              LDMessageDlg(Messages[6]+' #LINKS#',mtWarning,[mbOK],0);
              break;
            end;
            ReadLn(F,sTmp2);
            for j:= 1 to StrToInt(sTmp2) do begin
              TmpLink := TNodeLink.Create;
              ReadLn(F,sTmp2);
              TmpLink.sDescription := sTmp2;
              ReadLn(F,sTmp2);
              TmpLink.iNodeIdx := StrToInt(sTmp2);
              NewEntry.LinkList.Add(TmpLink);
            end;
          end;
          Memo1.SelStart := 1;
          if StrToInt(sTmp)=lLastPar then
            NewNode := TreeView1.Items.AddChild( LastNode,NewEntry.GetText)
          else begin
            lLastPar := StrToInt(sTmp);
            LastNode := TreeView1.Items[lLastPar];
            NewNode := TreeView1.Items.AddChild(LastNode,NewEntry.GetText);
          end;
          if NewEntry.LinkList.Count > 0 then
            CacheList.Add(IntToStr(TreeView1.Items.Count));
          NewNode.Data := NewEntry;
{          TreeView1.FullExpand;}
        end;
        if sTmp = '#HINT#' then begin
          NewEntry := THEntry.Create(etHint);
          ReadLn(F,sTmp);
          ReadLn(F,sTmp2);
          NewEntry.sEntries.sSimple := sTmp2;
          ReadLn(F,sTmp2);
          if sTmp2 <> '#TEXT#' then begin
            LDMessageDlg(Messages[6]+' #TEXT#',mtWarning,[mbOK],0);
            break;
          end;
          ReadLn(F,sTmp2);
          while sTmp2 <> '#FINISH#' do begin
            NewEntry.sEntries.sComplex.Add(sTmp2);
            ReadLn(F,sTmp2);
          end;
          if FileVer > 100 then begin
            ReadLn(F,sTmp2);
            if sTmp2 <> '#LINKS#' then begin
              LDMessageDlg(Messages[6]+' #LINKS#',mtWarning,[mbOK],0);
              break;
            end;
            ReadLn(F,sTmp2);
            for j:= 1 to StrToInt(sTmp2) do begin
              TmpLink := TNodeLink.Create;
              ReadLn(F,sTmp2);
              TmpLink.sDescription := sTmp2;
              ReadLn(F,sTmp2);
              TmpLink.iNodeIdx := StrToInt(sTmp2);
              NewEntry.LinkList.Add(TmpLink);
            end;
          end;
          Memo1.SelStart := 1;
          if StrToInt(sTmp)=lLastPar then
            NewNode := TreeView1.Items.AddChild( LastNode,NewEntry.GetText)
          else begin
            lLastPar := StrToInt(sTmp);
            LastNode := TreeView1.Items[lLastPar];
            NewNode := TreeView1.Items.AddChild(LastNode,NewEntry.GetText);
          end;
          if NewEntry.LinkList.Count > 0 then
            CacheList.Add(IntToStr(TreeView1.Items.Count));
          NewNode.Data := NewEntry;
{          TreeView1.FullExpand;}
        end;
      end;
    end
    else
      LDMessageDlg(Messages[7],mtError,[mbOK],0);
    end;
    RebuildLinks(CacheList);
  finally
    CacheList.Free;
    Closefile(F);
  end;
  end;
end;

procedure THREditor.Speichern1Click(Sender: TObject);
begin
  if (Edit1.Text = '') or (Edit2.Text = '')  then
    LDMessageDlg(Messages[2], mtError,[mbOK],0)
  else begin
    if CurrFilename <> '' then
      SaveTHR_110(CurrFilename)
    else begin
      SaveDialog1.Filename := '';
      SaveDialog1.FilterIndex := 1;
      if SaveDialog1.Execute then begin
        SaveTHR_110(SaveDialog1.Filename);
        CurrFilename := SaveDialog1.Filename;
      end;
    end;
  end;
end;

procedure THREditor.SaveTHR_110( TheFile : string );
Var F           : TextFile;
    i,j,k,l     : Integer;
    Owner       : THEntry;
    sFont       : String;
    CurNode     : TTreeNode;
    iLastOwner  : longint;
    iLastLevel  : longint;
    iCurLevel   : longint;
    TmpLink     : TNodeLink;
begin
  try
    ProgressInd.MaxValue := TreeView1.Items.Count+4;
    ProgressInd.Progress := 0;
    AssignFile(F,TheFile);
    Rewrite(F);
    { ...Daten schreiben ! }
    { Version }
    WriteLn(F,PRG_VER);
    ProgressInd.Progress := ProgressInd.Progress+1;
    { Titel }
    WriteLn(F,Edit1.Text);
    ProgressInd.Progress := ProgressInd.Progress+1;
    { Schriftart }
    Writeln(F,FontDialog1.Font.Name);
    Writeln(F,IntToStr(FontDialog1.Font.Color));
    Writeln(F,IntToStr(FontDialog1.Font.Size));
    if fsBold in FontDialog1.Font.Style then sFont := sFont+'1'
                                        else sFont := sFont+'0';
    if fsItalic in FontDialog1.Font.Style then sFont := sFont+'1'
                                        else sFont := sFont+'0';
    if fsUnderline in FontDialog1.Font.Style then sFont := sFont+'1'
                                        else sFont := sFont+'0';
    if fsStrikeOut in FontDialog1.Font.Style then sFont := sFont+'1'
                                        else sFont := sFont+'0';
    Writeln(F,sFont);
    ProgressInd.Progress := ProgressInd.Progress+1;
    { Autor }
    WriteLn(F,Edit2.Text);
    ProgressInd.Progress := ProgressInd.Progress+1;
    { Notiz }
    WriteLn(F,'#NOTICE<#');
    if Memo1.Lines.Count > 0 then
      for k:= 0 to Memo1.Lines.Count-1 do
        WriteLn(F,Memo1.Lines[k]);
    WriteLn(F,'#>NOTICE#');
    ProgressInd.Progress := ProgressInd.Progress+1;
    { Hinteintr‰ge }
    if TreeView1.Items.Count > 1 then begin
      CurNode := TreeView1.Items[1];
      iLastOwner := -1;
      iLastLevel := -1;
      while CurNode <> nil do begin
        ProgressInd.Progress := ProgressInd.Progress+1;
        Owner := CurNode.Data;
        if Owner.HType = etMM then begin
          WriteLn(F,'#MM#');
          iCurLevel := CurNode.Level;
          if ((CurNode.Index = 0) or
              (CurNode.Level <> iLastLevel)) then begin
            iLastOwner := CurNode.Parent.AbsoluteIndex;
            iLastLevel := CurNode.Level;
          end;
          WriteLn(F,IntToStr(iLastOwner));
          WriteLn(F,Owner.sEntries.sComplex.Strings[0]);
          WriteLn(F,Owner.sEntries.sComplex.Strings[1]);
          WriteLn(F,'#LINKS#');
          WriteLn(F,IntToStr(Owner.LinkList.Count));
          for l:=0 to Owner.LinkList.Count-1 do begin
            TmpLink := TNodeLink(Owner.LinkList.Items[l]);
            WriteLn(F,TmpLink.sDescription);
            WriteLn(F,IntToStr(TmpLink.pTreeNode.AbsoluteIndex));
          end;
        end;
        if Owner.HType = etTopic then begin
          WriteLn(F,'#TOPIC#');
          iCurLevel := CurNode.Level;
          if ((CurNode.Index = 0) or
              (CurNode.Level <> iLastLevel)) then begin
            iLastOwner := CurNode.Parent.AbsoluteIndex;
            iLastLevel := CurNode.Level;
          end;
          WriteLn(F,IntToStr(iLastOwner));
          WriteLn(F,Owner.sEntries.sSimple);
          WriteLn(F,'#LINKS#');
          WriteLn(F,IntToStr(Owner.LinkList.Count));
          for l:=0 to Owner.LinkList.Count-1 do begin
            TmpLink := TNodeLink(Owner.LinkList.Items[l]);
            WriteLn(F,TmpLink.sDescription);
            WriteLn(F,IntToStr(TmpLink.pTreeNode.AbsoluteIndex));
          end;
        end;
        if Owner.HType = etHint then begin
          WriteLn(F,'#HINT#');
          iCurLevel := CurNode.Level;
          if ((CurNode.Index = 0) or
              (CurNode.Level <> iLastLevel)) then begin
            iLastOwner := CurNode.Parent.AbsoluteIndex;
            iLastLevel := CurNode.Level;
          end;
          WriteLn(F,IntToStr(iLastOwner));
          WriteLn(F,Owner.sEntries.sSimple);
          WriteLn(F,'#TEXT#');
          For k:=0 to Owner.sEntries.sComplex.Count-1 do
            WriteLn(F,Owner.sEntries.sComplex[k]);
          WriteLn(F,'#FINISH#');
          WriteLn(F,'#LINKS#');
          WriteLn(F,IntToStr(Owner.LinkList.Count));
          for l:=0 to Owner.LinkList.Count-1 do begin
            TmpLink := TNodeLink(Owner.LinkList.Items[l]);
            WriteLn(F,TmpLink.sDescription);
            WriteLn(F,IntToStr(TmpLink.pTreeNode.AbsoluteIndex));
          end;
        end;
        if Owner.HType = etInfo then begin
          WriteLn(F,'#INFO#');
          iCurLevel := CurNode.Level;
          if ((CurNode.Index = 0) or
              (CurNode.Level <> iLastLevel)) then begin
            iLastOwner := CurNode.Parent.AbsoluteIndex;
            iLastLevel := CurNode.Level;
          end;
          WriteLn(F,IntToStr(iLastOwner));
          WriteLn(F,Owner.sEntries.sSimple);
          WriteLn(F,'#TEXT#');
          For k:=0 to Owner.sEntries.sComplex.Count-1 do
            WriteLn(F,Owner.sEntries.sComplex[k]);
          WriteLn(F,'#FINISH#');
          WriteLn(F,'#LINKS#');
          WriteLn(F,IntToStr(Owner.LinkList.Count));
          for l:=0 to Owner.LinkList.Count-1 do begin
            TmpLink := TNodeLink(Owner.LinkList.Items[l]);
            WriteLn(F,TmpLink.sDescription);
            WriteLn(F,IntToStr(TmpLink.pTreeNode.AbsoluteIndex));
          end;
        end;
        if Owner.HType = etPic then begin
          WriteLn(F,'#PIC#');
          iCurLevel := CurNode.Level;
          if ((CurNode.Index = 0) or
              (CurNode.Level <> iLastLevel)) then begin
            iLastOwner := CurNode.Parent.AbsoluteIndex;
            iLastLevel := CurNode.Level;
          end;
          WriteLn(F,IntToStr(iLastOwner));
          WriteLn(F,Owner.sEntries.sSimple);
          WriteLn(F,IntToStr(Owner.sEntries.sComplex.Count));
          for j:= 0 to Owner.sEntries.sComplex.Count-1 do begin
            WriteLn(F,Owner.sEntries.sComplex[j]);
            WriteLn(F,Owner.sEntries.sComplex2[j]);
          end;
          WriteLn(F,'#LINKS#');
          WriteLn(F,IntToStr(Owner.LinkList.Count));
          for l:=0 to Owner.LinkList.Count-1 do begin
            TmpLink := TNodeLink(Owner.LinkList.Items[l]);
            WriteLn(F,TmpLink.sDescription);
            WriteLn(F,IntToStr(TmpLink.pTreeNode.AbsoluteIndex));
          end;
        end;
        CurNode := CurNode.GetNext;
      end;
    end;
  finally
    Closefile(F);
  end;
end;

procedure THREditor.bersetzen2Click(Sender: TObject);
Var TheFName : string;
begin
  if (Edit1.Text = '') or (Edit2.Text = '')  then
    LDMessageDlg(Messages[2], mtError,[mbOK],0)
  else begin
    if CurrFilename = '' then begin
      SaveDialog1.Filename := '';
      SaveDialog1.FilterIndex := 2;
      if SaveDialog1.Execute then begin
        TheFName := SaveDialog1.Filename;
      end;
    end
    else begin
      TheFName := CurrFilename;
      TheFName := ChangeFileExt(TheFName, '.thl');
    end;
    if TheFName <> '' then
      CompileTHL_110(TheFName);
  end;
end;

procedure THREditor.CompileTHL_110( TheFile : string );
Var FCmp        : file of char;
    FPic        : file of char;
    FMM         : file of char;
    i           : Integer;
    OwnRef      : THEntry;
    sFont       : String;
    cTmp        : Char;
    Buffer      : array[0..256] of char;
    NumRead,
    NumWritten  : Integer;
    j           : Integer;
    k,l         : Integer;
    bKill       : Boolean;
    CurNode     : TTreeNode;
    iLastOwner  : longint;
    iLastLevel  : longint;
    iCurLevel   : longint;
    TmpLink     : TNodeLink;

   procedure VWriteLn( Line : string );
   Var SubBuffer       : array[0..4095] of char;
       Subi,
       SubNumWritten,
       Subj            : Integer;
   begin
     Subi := 0;
     for Subj:=0 to 4095 do
       SubBuffer[Subj]:=chr(0);
     for Subi:=0 to (Length(Line)-1) do
       SubBuffer[Subi]:= Line[Subi+1];
     SubBuffer[Subi] := chr(13);
     SubBuffer[Subi+1] := chr(10);
     BlockWrite(FCmp,SubBuffer,Length(Line)+2,SubNumWritten);
   end;

begin
  bKill := False;
  try
    CmpWnd.SetCaption('Compiler','Compiling...');
    CmpWnd.Show;
    CmpWnd.SetTextLine('General data');
    AssignFile(FCmp,TheFile);
    Rewrite(FCmp);
    { ...Daten schreiben ! }
    { Version }
    VWriteLn(PRG_VER);
    { Titel }
    VWriteLn(EncodeLine(Edit1.Text,'THL'));
    { Schriftart }
    VWriteLn(EncodeLine(FontDialog1.Font.Name,Edit1.Text));
    VWriteLn(EncodeLine(IntToStr(FontDialog1.Font.Color),Edit1.Text));
    VWriteLn(EncodeLine(IntToStr(FontDialog1.Font.Size),Edit1.Text));
    if fsBold in FontDialog1.Font.Style then sFont := sFont+'1'
                                        else sFont := sFont+'0';
    if fsItalic in FontDialog1.Font.Style then sFont := sFont+'1'
                                        else sFont := sFont+'0';
    if fsUnderline in FontDialog1.Font.Style then sFont := sFont+'1'
                                        else sFont := sFont+'0';
    if fsStrikeOut in FontDialog1.Font.Style then sFont := sFont+'1'
                                        else sFont := sFont+'0';
    VWriteLn(EncodeLine(sFont,Edit1.Text));
    { Autor }
    VWriteLn(EncodeLine(Edit2.Text,Edit1.Text));
    { Notiz }
    VWriteLn(EncodeLine('#NOTICE<#',Edit1.Text));
    for i:=0 to Memo1.Lines.Count-1 do
      VWriteLn(EncodeLine(Memo1.Lines[i],Edit1.Text));
    VWriteLn(EncodeLine('#>NOTICE#',Edit1.Text));
    { Hinteintr‰ge }
    VWriteLn(EncodeLine(IntToStr(TreeView1.Items.Count-1),Edit2.Text));
    if TreeView1.Items.Count > 1 then begin
      CurNode := TreeView1.Items[1];
      iLastOwner := -1;
      iLastLevel := -1;
      while CurNode <> nil do begin
        OwnRef := CurNode.Data;
        if OwnRef.HType = etTopic then begin
          CmpWnd.SetTextLine('Topic: '+OwnRef.sEntries.sSimple);
          VWriteLn(EncodeLine('#TOPIC#',Edit2.Text));
          iCurLevel := CurNode.Level;
          if ((CurNode.Index = 0) or
              (CurNode.Level <> iLastLevel)) then begin
            iLastOwner := CurNode.Parent.AbsoluteIndex;
            iLastLevel := CurNode.Level;
          end;
          VWriteLn(EncodeLine(IntToStr(iLastOwner),Edit2.Text));
          VWriteLn(EncodeLine(OwnRef.sEntries.sSimple,Edit2.Text));
          VWriteLn(EncodeLine('#LINKS#',Edit1.Text));
          VWriteLn(EncodeLine(IntToStr(OwnRef.LinkList.Count),Edit1.Text));
          for l:=0 to OwnRef.LinkList.Count-1 do begin
            TmpLink := TNodeLink(OwnRef.LinkList.Items[l]);
            VWriteLn(EncodeLine(TmpLink.sDescription,Edit1.Text));
            VWriteLn(EncodeLine(IntToStr(TmpLink.pTreeNode.AbsoluteIndex),
                     Edit1.Text));
          end;
        end;
        if OwnRef.HType = etHint then begin
          CmpWnd.SetTextLine('Hint: '+OwnRef.sEntries.sComplex[0]);;
          VWriteLn(EncodeLine('#HINT#',Edit2.Text));
          iCurLevel := CurNode.Level;
          if ((CurNode.Index = 0) or
              (CurNode.Level <> iLastLevel)) then begin
            iLastOwner := CurNode.Parent.AbsoluteIndex;
            iLastLevel := CurNode.Level;
          end;
          VWriteLn(EncodeLine(IntToStr(iLastOwner),Edit2.Text));
          VWriteLn(EncodeLine('#TEXT#',Edit2.Text));
          for l:=0 to OwnRef.sEntries.sComplex.Count-1 do
            VWriteLn(EncodeLine(OwnRef.sEntries.sComplex[l],Edit2.Text));
          VWriteLn(EncodeLine('#FINISH#',Edit2.Text));
          VWriteLn(EncodeLine('#LINKS#',Edit1.Text));
          VWriteLn(EncodeLine(IntToStr(OwnRef.LinkList.Count),Edit1.Text));
          for l:=0 to OwnRef.LinkList.Count-1 do begin
            TmpLink := TNodeLink(OwnRef.LinkList.Items[l]);
            VWriteLn(EncodeLine(TmpLink.sDescription,Edit1.Text));
            VWriteLn(EncodeLine(IntToStr(TmpLink.pTreeNode.AbsoluteIndex),
                     Edit1.Text));
          end;
        end;
        if OwnRef.HType = etInfo then begin
          CmpWnd.SetTextLine('Info: '+OwnRef.sEntries.sComplex[0]);;
          VWriteLn(EncodeLine('#INFO#',Edit2.Text));
          iCurLevel := CurNode.Level;
          if ((CurNode.Index = 0) or
              (CurNode.Level <> iLastLevel)) then begin
            iLastOwner := CurNode.Parent.AbsoluteIndex;
            iLastLevel := CurNode.Level;
          end;
          VWriteLn(EncodeLine(IntToStr(iLastOwner),Edit2.Text));
          VWriteLn(EncodeLine(OwnRef.sEntries.sSimple,Edit2.Text));
          VWriteLn(EncodeLine('#TEXT#',Edit2.Text));
          for l:=0 to OwnRef.sEntries.sComplex.Count-1 do
            VWriteLn(EncodeLine(OwnRef.sEntries.sComplex[l],Edit2.Text));
          VWriteLn(EncodeLine('#FINISH#',Edit2.Text));
          VWriteLn(EncodeLine('#LINKS#',Edit1.Text));
          VWriteLn(EncodeLine(IntToStr(OwnRef.LinkList.Count),Edit1.Text));
          for l:=0 to OwnRef.LinkList.Count-1 do begin
            TmpLink := TNodeLink(OwnRef.LinkList.Items[l]);
            VWriteLn(EncodeLine(TmpLink.sDescription,Edit1.Text));
            VWriteLn(EncodeLine(IntToStr(TmpLink.pTreeNode.AbsoluteIndex),
                     Edit1.Text));
          end;
        end;
        if OwnRef.HType = etMM then begin
          CmpWnd.SetTextLine('Multimedia file: '+OwnRef.sEntries.sComplex[1]);
          VWriteLn(EncodeLine('#MM#',Edit2.Text));
          iCurLevel := CurNode.Level;
          if ((CurNode.Index = 0) or
              (CurNode.Level <> iLastLevel)) then begin
            iLastOwner := CurNode.Parent.AbsoluteIndex;
            iLastLevel := CurNode.Level;
          end;
          VWriteLn(EncodeLine(IntToStr(iLastOwner),Edit2.Text));
          { Hier muﬂ wirklich ein MM-File abgelegt werden }
          if OwnRef.sEntries.sComplex[0]<>'' then begin
            if FileExists(OwnRef.sEntries.sComplex[1]) then begin
              VWriteLn(EncodeLine(ExtractFileExt(OwnRef.sEntries.sComplex[1]),
                      Edit2.Text));
              VWriteLn(EncodeLine(OwnRef.sEntries.sComplex[0],Edit2.Text));
              try
                AssignFile(FMM,OwnRef.sEntries.sComplex[1]);
                Reset(FMM);
                VWriteLn(IntToStr(Filesize(FMM)));
                repeat
                  BlockRead(FMM, Buffer, SizeOf(Buffer), NumRead);
                  BlockWrite(FCmp,Buffer,NumRead, NumWritten);
                until (NumRead = 0) or (NumWritten <> NumRead);
              finally
                CloseFile(FMM);
              end;
              VWriteLn(EncodeLine('#MMEND#',Edit2.Text));
            end
            else begin
              LDMessageDlg(OwnRef.sEntries.sComplex[1]+#13+Messages[8]
                         ,mtError,[mbOK],0);
              bKill := True;
            end;
          end;
          VWriteLn(EncodeLine('#LINKS#',Edit1.Text));
          VWriteLn(EncodeLine(IntToStr(OwnRef.LinkList.Count),Edit1.Text));
          for l:=0 to OwnRef.LinkList.Count-1 do begin
            TmpLink := TNodeLink(OwnRef.LinkList.Items[l]);
            VWriteLn(EncodeLine(TmpLink.sDescription,Edit1.Text));
            VWriteLn(EncodeLine(IntToStr(TmpLink.pTreeNode.AbsoluteIndex),
                     Edit1.Text));
          end;
        end;
        if OwnRef.HType = etPic then begin
          CmpWnd.SetTextLine('Picture: '+OwnRef.sEntries.sSimple);
          VWriteLn(EncodeLine('#PIC#',Edit2.Text));
          iCurLevel := CurNode.Level;
          if ((CurNode.Index = 0) or
              (CurNode.Level <> iLastLevel)) then begin
            iLastOwner := CurNode.Parent.AbsoluteIndex;
            iLastLevel := CurNode.Level;
          end;
          VWriteLn(EncodeLine(IntToStr(iLastOwner),Edit2.Text));
          { Hier muﬂ wirklich ein Bild abgelegt werden }
          if OwnRef.sEntries.sSimple<>'' then begin
            if FileExists(OwnRef.sEntries.sSimple) then begin
              VWriteLn(EncodeLine(ExtractFileExt(OwnRef.sEntries.sSimple),
                      Edit2.Text));
              try
                AssignFile(FPic,OwnRef.sEntries.sSimple);
                Reset(FPic);
                VWriteLn(IntToStr(Filesize(FPic)));
                repeat
                  BlockRead(FPic, Buffer, SizeOf(Buffer), NumRead);
                  BlockWrite(FCmp,Buffer, NumRead,NumWritten );
                until NumRead = 0;
              finally
                CloseFile(FPic);
              end;
              VWriteLn(EncodeLine('#PICEND#',Edit2.Text));
              VWriteLn(EncodeLine(IntToStr(OwnRef.sEntries.sComplex.Count),
                                      Edit2.Text));
              for k := 0 to OwnRef.sEntries.sComplex.Count-1 do begin
                VWriteLn(EncodeLine(OwnRef.sEntries.sComplex[k],Edit2.Text));
                VWriteLn(EncodeLine(OwnRef.sEntries.sComplex2[k],Edit2.Text));
              end;
            end
            else begin
              LDMessageDlg(OwnRef.sEntries.sSimple+#13+Messages[8]
                         ,mtError,[mbOK],0);
              bKill := True;
            end;
          end;
          VWriteLn(EncodeLine('#LINKS#',Edit1.Text));
          VWriteLn(EncodeLine(IntToStr(OwnRef.LinkList.Count),Edit1.Text));
          for l:=0 to OwnRef.LinkList.Count-1 do begin
            TmpLink := TNodeLink(OwnRef.LinkList.Items[l]);
            VWriteLn(EncodeLine(TmpLink.sDescription,Edit1.Text));
            VWriteLn(EncodeLine(IntToStr(TmpLink.pTreeNode.AbsoluteIndex),
                     Edit1.Text));
          end;

        end;
        if bKill then break;
        CurNode := CurNode.GetNext;
      end;
    end;
  finally
    Closefile(FCmp);
    if bKill then Erase(FCmp);
    CmpWnd.Close;
  end;
end;

procedure THREditor.Speichernals1Click(Sender: TObject);
begin
  if (Edit1.Text = '') or (Edit2.Text = '')  then
    LDMessageDlg(Messages[2], mtError,[mbOK],0)
  else begin
    SaveDialog1.Filename := '';
    SaveDialog1.FilterIndex := 1;
    if SaveDialog1.Execute then begin
      SaveTHR_110(SaveDialog1.Filename);
      CurrFilename := SaveDialog1.Filename;
    end;
  end;

end;

procedure THREditor.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if LDMessageDlg(Messages[10]+' ('+CurrFilename+')',mtConfirmation,[mbYES,mbNO],0) = mrYES then
    Speichern1Click(Sender);
end;

procedure THREditor.ShowForm;
begin
  if WindowState <> wsNormal then
    WindowState := wsNormal;
  Show;
end;

procedure THREditor.Kopieren1Click(Sender: TObject);
begin
  if TreeView1.Selected.Text <> DEF_ROOT then begin
    MoveNodeID := TreeView1.Selected.AbsoluteIndex;
    EditorClipMenu.Items[6].Enabled := True;
  end
  else
    EditorClipMenu.Items[6].Enabled := False;
end;

procedure THREditor.Einfgen1Click(Sender: TObject);
Var OwnRef      : THEntry;
    Target      : THEntry;
begin
{  if TreeView1.Selected.Text = DEF_ROOT then begin
    OwnRef := BufferNode.Item[0].Data;
    TreeView1.Items.AddChild(TreeView1.Selected, OwnRef.GetText);
    TreeView1.Selected.Expand(False);
  end
  else begin
    Target := THEntry(TreeView1.Selected.Data);
    if Target.HType = etTopic then begin
      OwnRef := BufferNode.Item[0].Data;
      TreeView1.Items.AddChild(TreeView1.Selected, OwnRef.GetText);
      TreeView1.Selected.Expand(False);
    end;
  end;
}
end;

procedure THREditor.BitBtn4Click(Sender: TObject);
begin
  NodesLinkWnd.ShowNEdit(  TreeView1.Selected );
end;

procedure THREditor.RebuildLinks( CList : TStringList );
Var iRun,
    jRun      : Integer;
    OneEntry  : THEntry;
    Node      : TNodeLink;
begin
try
  CmpWnd.SetCaption('Editor','Rebuilding links...');
  CmpWnd.Show;
  for iRun := 0 to CList.Count-1 do
  begin
    OneEntry := THEntry(TreeView1.Items[StrToInt(CList.Strings[iRun])-1].Data);
    if OneEntry.LinkList.Count > 0 then begin
      for jRun := 0 to OneEntry.LinkList.Count-1 do
      begin
        CmpWnd.SetTextLine(TreeView1.Items[iRun].Text+' '+IntToStr(jRun));
        Node := TNodeLink(OneEntry.LinkList.Items[jRun]);
        Node.pTreeNode := HREditor.TreeView1.Items[Node.iNodeIdx];
        CmpWnd.Refresh;
        Application.ProcessMessages;
      end;
    end;
  end;
finally
  CmpWnd.Close;
end;
end;

procedure THREditor.TreeView1DragDrop(Sender, Source: TObject; X,
  Y: Integer);
var
  AnItem       : TTreeNode;
  AttachMode   : TNodeAttachMode;
  HT           : THitTests;
  TheData      : THEntry;
  Tricky       : TTreeNode;
begin
  if TreeView1.Selected = nil then Exit;
  AnItem := TreeView1.GetNodeAt(X, Y);

  if (AnItem <> nil) then
  begin
{
    if (htOnItem in HT) or (htOnIcon in HT) then AttachMode := naAddChild
    else if htNowhere in HT then AttachMode := naAdd
    else if htOnIndent in HT then AttachMode := naInsert;
}
    TreeView1.Items.BeginUpdate;
    Tricky := nil;
    if AnItem.Text = DEF_ROOT then
      AttachMode := naAddChild
    else begin
      TheData := THEntry(AnItem.Data);
      if TheData.HType = etTopic then begin
        if AnItem.Count = 0 then
          Tricky := TreeView1.Items.AddChild(AnItem,'TRICKY ITEM');
        AttachMode := naAddChild;
      end
      else
        AttachMode := naInsert;
    end;
    TreeView1.Selected.MoveTo(AnItem, AttachMode);
    if (Tricky <> nil) then
      Tricky.Delete;
    TreeView1.Items.EndUpdate;
  end;
end;
procedure THREditor.TreeView1DragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := Source is TTreeView;
end;

procedure THREditor.Neu1Click(Sender: TObject);
begin
  Initialise;
end;

end.
