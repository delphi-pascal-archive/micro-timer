program MicroTimerTutorial;

uses
  Forms,
  Main in 'Main.pas' {MainForm};

{$R *.res}
{$R WindowsXP.RES}

begin
  Application.Initialize;
  Application.Title := 'Tutorial MicroTimer';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
