program AdvHint1;

uses
  Forms,
  Main in 'MAIN.PAS' {MainForm},
  hredit in 'hredit.pas' {HREditor},
  topedit in 'topedit.pas' {TopicEdit},
  hntedit in 'hntedit.pas' {HintEdit},
  pcedit in 'pcedit.pas' {PicEdit},
  about in 'about.pas' {AboutBox},
  reader in 'reader.pas' {ReaderForm},
  picview in 'picview.pas' {ShowPic},
  mumeedit in 'mumeedit.pas' {MMEdit},
  hntwnd in 'hntwnd.pas' {HintWindow},
  MediaWnd in 'MediaWnd.pas' {MMWnd},
  vopen in 'vopen.pas' {VerbOpen},
  CompWnd in 'CompWnd.pas' {CmpWnd},
  LDMsgDlg in 'LDMsgDlg.pas',
  langDlg in 'langDlg.pas' {LangSel};

{$R *.RES}

begin
  Application.Title := 'The Hint Library';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(THREditor, HREditor);
  Application.CreateForm(TTopicEdit, TopicEdit);
  Application.CreateForm(THintEdit, HintEdit);
  Application.CreateForm(TPicEdit, PicEdit);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.CreateForm(TReaderForm, ReaderForm);
  Application.CreateForm(TShowPic, ShowPic);
  Application.CreateForm(TMMEdit, MMEdit);
  Application.CreateForm(THintWindow, HintWindow);
  Application.CreateForm(TMMWnd, MMWnd);
  Application.CreateForm(TVerbOpen, VerbOpen);
  Application.CreateForm(TCmpWnd, CmpWnd);
  Application.CreateForm(TLangSel, LangSel);
  MainForm.Initialize;
  MainForm.Show;
  MainForm.CmdParse;
  Application.Run;
end.
