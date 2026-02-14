unit simpleedit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ComCtrls;

type
  EntryType = (ET_INFO, ET_THEMA, ET_HINT, ET_PIC);
type
  TEntryEdit = class(TForm)
    Label1: TLabel;
    DescEdit: TEdit;
    Textlabel: TLabel;
    TextField: TMemo;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    OpenDialog1: TOpenDialog;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
  private
    ResMode  : Boolean;
    { Private-Deklarationen }
  public
    function GetNew( Owner : TTreeNode;ET : EntryType ): Boolean;
    { Public-Deklarationen }
  end;

var
  EntryEdit: TEntryEdit;

implementation

uses hredit;
                  
{$R *.DFM}

function TEntryEdit.GetNew( Owner : TTreeNode;ET : EntryType ): Boolean;
Var NewNode : TTreeNode;
begin
  case ET of
  ET_THEMA  : begin
                DescEdit.Text := '';
                DescEdit.ReadOnly := False;
                TextField.Enabled := False;
                ShowModal;
                if ResMode then
                  NewNode := HREditor.TreeView1.Items.AddChild(
                             Owner,DescEdit.Text);
              end;
  ET_HINT   : begin
                DescEdit.Text := '';
                DescEdit.ReadOnly := False;
                TextField.Enabled := True;
                TextField.Lines.Clear;
                ShowModal;
                if ResMode then begin
                  NewNode := HREditor.TreeView1.Items.AddChild(
                             Owner,DescEdit.Text);
                  NewNode.Data := TextField.Lines;           
                end;
              end;
  end;
end;

procedure TEntryEdit.BitBtn1Click(Sender: TObject);
begin
  ResMode := True;
  Close;
end;

procedure TEntryEdit.BitBtn2Click(Sender: TObject);
begin
  ResMode := False;
  Close;
end;

end.
