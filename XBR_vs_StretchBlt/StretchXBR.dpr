program StretchXBR;

uses
  Forms,
  uDemo in 'uDemo.pas' {FrmDemoMain},
  uStretchXBR in 'uStretchXBR.pas';

{$R *.res}

begin
  Application.Initialize;
  //Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmDemoMain, FrmDemoMain);
  Application.Run;
end.

