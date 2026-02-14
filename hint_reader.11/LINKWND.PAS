unit linkwnd;

{ LANG TEXT RANGE: 750-754 }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Grids, Main, ComCtrls;

type
  TNodesLinkWnd = class(TForm)
    StringGrid1: TStringGrid;
    WndClose: TBitBtn;
    DelButton: TBitBtn;
    procedure StringGrid1SelectCell(Sender: TObject; Col, Row: Longint;
      var CanSelect: Boolean);
    procedure WndCloseClick(Sender: TObject);
    procedure StringGrid1DragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure StringGrid1DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure DelButtonClick(Sender: TObject);
  private
    { Private-Deklarationen }
    OwnerRef : TTreeNode;
    CurrRow  : Integer;
    WndCaption  : string;
  public
    { Public-Deklarationen }
    procedure ShowNEdit( OwnerObj : TTreeNode );
    procedure SetLanguage( HL : THandle );
  end;

var
  NodesLinkWnd: TNodesLinkWnd;

implementation

{$R *.DFM}

uses Hredit;

procedure TNodesLinkWnd.StringGrid1SelectCell(Sender: TObject; Col, Row: Longint;
  var CanSelect: Boolean);
begin
  CurrRow := Row;
  if Col = 0 then
    CanSelect := True
  else
    CanSelect := False;
end;

procedure TNodesLinkWnd.WndCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TNodesLinkWnd.ShowNEdit( OwnerObj : TTreeNode );
Var i        : Integer;
    TmpData  : THEntry;
begin
  NodesLinkWnd.Caption :=  WndCaption + ' '+OwnerObj.Text;
  StringGrid1.RowCount := 2;
  StringGrid1.Cells[0,1]:='';
  StringGrid1.Cells[1,1]:='';
  TmpData := THEntry(OwnerObj.Data);
  if TmpData.GetNumLinks > 1 then
    StringGrid1.RowCount := TmpData.GetNumLinks+1;
  for i:=0 to TmpData.GetNumLinks-1 do begin
    StringGrid1.Cells[0,i+1] := TmpData.GetLinkDesc(i);
    StringGrid1.Cells[1,i+1] := TmpData.GetLinkDestText(i);
  end;
  OwnerRef := OwnerObj;
  Show;
end;

procedure TNodesLinkWnd.StringGrid1DragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := Source is TTreeView;
end;

procedure TNodesLinkWnd.StringGrid1DragDrop(Sender, Source: TObject; X,
  Y: Integer);
Var TmpEntry    : THEntry;
    NewLink     : TNodeLink;
begin
  NewLink := TNodeLink.Create;
  BringToFront;
  if StringGrid1.Cells[1,1] <> '' then
    StringGrid1.RowCount := StringGrid1.RowCount+1;
  TmpEntry := THEntry((Source as TTreeView).Selected.Data);
  if TmpEntry = nil then
    StringGrid1.Cells[1,StringGrid1.RowCount-1] := DEF_ROOT
  else
    StringGrid1.Cells[1,StringGrid1.RowCount-1] := TmpEntry.GetText;
  CurrRow := StringGrid1.RowCount-1;
  NewLink.sDescription := '';
  NewLink.iNodeIdx := -1;
  NewLink.pTreeNode := TTreeNode((Source as TTreeView).Selected);
  TmpEntry := THEntry(OwnerRef.Data);
  TmpEntry.LinkList.Add(NewLink);
end;

procedure TNodesLinkWnd.FormCreate(Sender: TObject);
begin
  CurrRow := -1;
end;

procedure TNodesLinkWnd.FormClose(Sender: TObject;
  var Action: TCloseAction);
Var iRun    : Integer;
    TmpData : THEntry;
    TmpNode : TNodeLink;
begin
  if StringGrid1.Cells[1,1]<>'' then begin
    for iRun:= 1 to StringGrid1.RowCount-1 do begin
      TmpData := THEntry(OwnerRef.Data);
      TmpNode := TNodeLink(TmpData.LinkList.Items[iRun-1]);
      TmpNode.sDescription := StringGrid1.Cells[0,iRun];
    end;
  end;
end;

procedure TNodesLinkWnd.DelButtonClick(Sender: TObject);
Var TmpData : THEntry;
    TmpNode : TNodeLink;
    i       : Integer;
begin
  TmpData := THEntry(OwnerRef.Data);
  if ((CurrRow > -1) AND (CurrRow <= TmpData.Linklist.Count)) then begin
    TmpNode := TNodeLink(TmpData.LinkList.Items[CurrRow-1]);
    TmpData.LinkList.Remove(TmpNode);
    StringGrid1.Rows[CurrRow].Clear;
    if CurrRow < StringGrid1.RowCount then
      for i:=CurrRow to StringGrid1.RowCount do begin
        StringGrid1.Cells[0,i] := StringGrid1.Cells[0,i+1];
        StringGrid1.Cells[1,i] := StringGrid1.Cells[1,i+1];
      end;
    if StringGrid1.RowCount > 2 then
      StringGrid1.RowCount := StringGrid1.RowCount-1;
  end;
end;

procedure TNodesLinkWnd.SetLanguage( HL : THandle );
Var Buffer : array[0..254] of char;
begin
  LoadString(HL,750,Buffer,sizeof(Buffer));
  WndCaption := StrPas(Buffer);
  LoadString(HL,751,Buffer,sizeof(Buffer));
  StringGrid1.Cells[0,0] := StrPas(Buffer);
  LoadString(HL,752,Buffer,sizeof(Buffer));
  StringGrid1.Cells[1,0] := StrPas(Buffer);
  LoadString(HL,753,Buffer,sizeof(Buffer));
  DelButton.Caption := StrPas(Buffer);
  LoadString(HL,754,Buffer,sizeof(Buffer));
  WndClose.Caption := StrPas(Buffer);
end;

end.
