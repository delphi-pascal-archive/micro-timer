unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, MicroTimer;

type
  TMainForm = class(TForm)
    Book: TNotebook;
    HeaderPageA: TLabel;
    HeaderBevelA: TBevel;
    LabelPageA_1: TLabel;
    LabelPageA_3: TLabel;
    ButtonsPanel: TPanel;
    NextBtn: TButton;
    LabelPageB_1: TLabel;
    LabelPageB_2: TLabel;
    PictureA: TImage;
    LabelPageB_3: TLabel;
    HeaderPageB: TLabel;
    HeaderBevelB: TBevel;
    HeaderPageC: TLabel;
    HeaderBevelC: TBevel;
    LabelPageC_1: TLabel;
    LabelPageC_2: TLabel;
    LabelPageC_3: TLabel;
    LabelPageC_4: TLabel;
    LabelPageC_5: TLabel;
    PictureB: TImage;
    LabelPageC_6: TLabel;
    LabelPageC_7: TLabel;
    Label1: TLabel;
    LabelPageA_2: TLabel;
    procedure NextBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.NextBtnClick(Sender: TObject); // Clic sur "Suivant"
begin
 Book.PageIndex := Book.PageIndex + 1; // On avance d'une page
 if NextBtn.Caption = 'Exit' then Close;  // Si le bouton est Quitter, on quitte
 if Book.PageIndex = Book.Pages.Count - 1 then NextBtn.Caption := 'Quitter'; // Si c'est la dernière page, on met le bouton à Quitter
end;

procedure TMainForm.FormCreate(Sender: TObject); // Création de la fiche ...
begin
 DoubleBuffered := True;  // On évite les scintillements ...
 Book.DoubleBuffered := True;  // Idem ...
end;

end.
