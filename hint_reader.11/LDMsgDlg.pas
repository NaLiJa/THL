unit LDMsgDlg;

interface
{ Message dialog }
uses Windows, Messages, SysUtils, CommDlg, Classes, Graphics, Controls,
     Forms,Dialogs;
type
  TLDMessageForm = class(TForm)
  private
    procedure HelpButtonClick(Sender: TObject);
  end;

type
  TMsgDlgType = (mtWarning, mtError, mtInformation, mtConfirmation, mtCustom);
  TMsgDlgBtn = (mbYes, mbNo, mbOK, mbCancel, mbAbort, mbRetry, mbIgnore,
    mbAll, mbHelp);
  TMsgDlgButtons = set of TMsgDlgBtn;

const
  mbYesNoCancel = [mbYes, mbNo, mbCancel];
  mbOKCancel = [mbOK, mbCancel];
  mbAbortRetryIgnore = [mbAbort, mbRetry, mbIgnore];

Var LDMSG_Language : THandle;

function CreateLDMessageDialog(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons): TForm;
function LDMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint): Integer;
function LDMessageDlgPos(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint; X, Y: Integer): Integer;

implementation

{ Message dialog }
uses StdCtrls, ExtCtrls, Consts, Printers;
function Max(I, J: Integer): Integer;
begin
  if I > J then Result := I else Result := J;
end;

function GetAveCharSize(Canvas: TCanvas): TPoint;
var
  I: Integer;
  Buffer: array[0..51] of Char;
begin
  for I := 0 to 25 do Buffer[I] := Chr(I + Ord('A'));
  for I := 0 to 25 do Buffer[I + 26] := Chr(I + Ord('a'));
  GetTextExtentPoint(Canvas.Handle, Buffer, 52, TSize(Result));
  Result.X := Result.X div 52;
end;
procedure TLDMessageForm.HelpButtonClick(Sender: TObject);
begin
  Application.HelpContext(HelpContext);
end;

function CreateLDMessageDialog(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons): TForm;
const
  mcHorzMargin = 8;
  mcVertMargin = 8;
  mcHorzSpacing = 10;
  mcVertSpacing = 10;
  mcButtonWidth = 50;
  mcButtonHeight = 14;
  mcButtonSpacing = 4;
const
  IconIDs: array[TMsgDlgType] of PChar = (IDI_EXCLAMATION, IDI_HAND,
    IDI_ASTERISK, IDI_QUESTION, nil);
  ButtonNames: array[TMsgDlgBtn] of string = (
    'Yes', 'No', 'OK', 'Cancel', 'Abort', 'Retry', 'Ignore', 'All', 'Help');
  ModalResults: array[TMsgDlgBtn] of Integer = (
    mrYes, mrNo, mrOk, mrCancel, mrAbort, mrRetry, mrIgnore, mrAll, 0);
var
  Captions: array[TMsgDlgType] of string;
  ButtonCaptions: array[TMsgDlgBtn] of String;
  DialogUnits: TPoint;
  HorzMargin, VertMargin, HorzSpacing, VertSpacing, ButtonWidth,
  ButtonHeight, ButtonSpacing, ButtonCount, ButtonGroupWidth,
  IconTextWidth, IconTextHeight, X: Integer;
  B, DefaultButton, CancelButton: TMsgDlgBtn;
  IconID: PChar;
  TextRect: TRect;
  TBuffer : array[0..254] of char;
begin
  Result := TLDMessageForm.CreateNew(Application);
  with Result do
  begin
    LoadString(LDMSG_Language,50,TBuffer,sizeof(TBuffer));
    Captions[mtWarning] := StrPas(TBuffer);
    LoadString(LDMSG_Language,51,TBuffer,sizeof(TBuffer));
    Captions[mtError] := StrPas(TBuffer);
    LoadString(LDMSG_Language,52,TBuffer,sizeof(TBuffer));
    Captions[mtInformation] := StrPas(TBuffer);
    LoadString(LDMSG_Language,53,TBuffer,sizeof(TBuffer));
    Captions[mtConfirmation] := StrPas(TBuffer);
    Captions[mtCustom] := '';
    LoadString(LDMSG_Language,60,TBuffer,sizeof(TBuffer));
    ButtonCaptions[mbYes] := StrPas(TBuffer);
    LoadString(LDMSG_Language,61,TBuffer,sizeof(TBuffer));
    ButtonCaptions[mbNo] := StrPas(TBuffer);
    LoadString(LDMSG_Language,62,TBuffer,sizeof(TBuffer));
    ButtonCaptions[mbOk] := StrPas(TBuffer);
    LoadString(LDMSG_Language,63,TBuffer,sizeof(TBuffer));
    ButtonCaptions[mbCancel] := StrPas(TBuffer);
    LoadString(LDMSG_Language,64,TBuffer,sizeof(TBuffer));
    ButtonCaptions[mbAbort] := StrPas(TBuffer);
    LoadString(LDMSG_Language,65,TBuffer,sizeof(TBuffer));
    ButtonCaptions[mbRetry] := StrPas(TBuffer);
    LoadString(LDMSG_Language,66,TBuffer,sizeof(TBuffer));
    ButtonCaptions[mbIgnore] := StrPas(TBuffer);
    LoadString(LDMSG_Language,67,TBuffer,sizeof(TBuffer));
    ButtonCaptions[mbAll] := StrPas(TBuffer);
    LoadString(LDMSG_Language,68,TBuffer,sizeof(TBuffer));
    ButtonCaptions[mbHelp] := StrPas(TBuffer);

    BorderStyle := bsDialog;
    Canvas.Font := Font;
    DialogUnits := GetAveCharSize(Canvas);
    HorzMargin := MulDiv(mcHorzMargin, DialogUnits.X, 4);
    VertMargin := MulDiv(mcVertMargin, DialogUnits.Y, 8);
    HorzSpacing := MulDiv(mcHorzSpacing, DialogUnits.X, 4);
    VertSpacing := MulDiv(mcVertSpacing, DialogUnits.Y, 8);
    ButtonWidth := MulDiv(mcButtonWidth, DialogUnits.X, 4);
    ButtonHeight := MulDiv(mcButtonHeight, DialogUnits.Y, 8);
    ButtonSpacing := MulDiv(mcButtonSpacing, DialogUnits.X, 4);
    SetRect(TextRect, 0, 0, Screen.Width div 2, 0);
    DrawText(Canvas.Handle, PChar(Msg), -1, TextRect,
      DT_CALCRECT or DT_WORDBREAK);
    IconID := IconIDs[DlgType];
    IconTextWidth := TextRect.Right;
    IconTextHeight := TextRect.Bottom;
    if IconID <> nil then
    begin
      Inc(IconTextWidth, 32 + HorzSpacing);
      if IconTextHeight < 32 then IconTextHeight := 32;
    end;
    ButtonCount := 0;
    for B := Low(TMsgDlgBtn) to High(TMsgDlgBtn) do
      if B in Buttons then Inc(ButtonCount);
    ButtonGroupWidth := 0;
    if ButtonCount <> 0 then
      ButtonGroupWidth := ButtonWidth * ButtonCount +
        ButtonSpacing * (ButtonCount - 1);
    ClientWidth := Max(IconTextWidth, ButtonGroupWidth) + HorzMargin * 2;
    ClientHeight := IconTextHeight + ButtonHeight + VertSpacing +
      VertMargin * 2;
    Left := (Screen.Width div 2) - (Width div 2);
    Top := (Screen.Height div 2) - (Height div 2);
    if DlgType <> mtCustom then
      Caption := Captions[DlgType]
    else
      Caption := Application.Title;
    if IconID <> nil then
      with TImage.Create(Result) do
      begin
        Name := 'Image';
        Parent := Result;
        Picture.Icon.Handle := LoadIcon(0, IconID);
        SetBounds(HorzMargin, VertMargin, 32, 32);
      end;
    with TLabel.Create(Result) do
    begin
      Name := 'Message';
      Parent := Result;
      WordWrap := True;
      Caption := Msg;
      BoundsRect := TextRect;
      SetBounds(IconTextWidth - TextRect.Right + HorzMargin, VertMargin,
        TextRect.Right, TextRect.Bottom);
    end;
    if mbOk in Buttons then DefaultButton := mbOk else
      if mbYes in Buttons then DefaultButton := mbYes else
        DefaultButton := mbRetry;
    if mbCancel in Buttons then CancelButton := mbCancel else
      if mbNo in Buttons then CancelButton := mbNo else
        CancelButton := mbOk;
    X := (ClientWidth - ButtonGroupWidth) div 2;
    for B := Low(TMsgDlgBtn) to High(TMsgDlgBtn) do
      if B in Buttons then
        with TButton.Create(Result) do
        begin
          Name := ButtonNames[B];
          Parent := Result;
          Caption := ButtonCaptions[B];
          ModalResult := ModalResults[B];
          if B = DefaultButton then Default := True;
          if B = CancelButton then Cancel := True;
          SetBounds(X, IconTextHeight + VertMargin + VertSpacing,
            ButtonWidth, ButtonHeight);
          Inc(X, ButtonWidth + ButtonSpacing);
          if B = mbHelp then
            OnClick := TLDMessageForm(Result).HelpButtonClick;
        end;
  end;
end;

function LDMessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint): Integer;
begin
  Result := LDMessageDlgPos(Msg, DlgType, Buttons, HelpCtx, -1, -1);
end;

function LDMessageDlgPos(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint; X, Y: Integer): Integer;
begin
  with CreateLDMessageDialog(Msg, DlgType, Buttons) do
    try
      HelpContext := HelpCtx;
      if X >= 0 then Left := X;
      if Y >= 0 then Top := Y;
      Result := ShowModal;
    finally
      Free;
    end;
end;

end.
