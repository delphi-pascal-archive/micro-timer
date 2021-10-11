{------------------------------- MICRO TIMER ----------------------------------
Ce composant s'utilise exactement comme un Timer normal, sauf que l'intervalle
est en microsecondes : donc, 1 => 1 microseconde, 1000 => 1 milliseconde, et
1000000 => 1 seconde.
Code lourdement comment�.
Auteur : Bacterius (thomas.beneteau@yahoo.fr, thomas777@live.fr).

Pour tout Delphi inf�rieur � Delphi 4 : changez Int64 en Cardinal - pas trop de
cons�quences.

--- AVERTISSEMENT ---

Ne mettez pas des tonnes de timers dans une application : 4 MicroTimers,
c'est un maximum !
-------------------------------------------------------------------------------}

unit MicroTimer; // MicroTimer !

interface

uses
  Windows, Messages, SysUtils, Classes, Forms; // Unit�s requises

type
  TTimerThrd = class; // Classe non d�finie pour l'instant de TTimerThrd (pour des raisons de compilation)

  TNotifyEvent = procedure(Sender: TObject) of object; // D�finition de TNotifyEvent

  TMicroTimer = class(TComponent) // Notre composant Timer !!
  private
    { D�clarations priv�es }
    FEnabled: Boolean; // Champ objet Enabled
    FInterval: Int64; // Champ objet Interval
    FThrd: TTimerThrd; // Variable du thread timer
    FOnTimer: TNotifyEvent; // Gestionnaire d'�v�nement OnTimer
    FPriority: TThreadPriority; // Priorit� du thread
    procedure SetOnTimer(Value: TNotifyEvent); // Setter OnTimer
    procedure SetEnabled(Value: Boolean);  // Setter Enabled
    procedure SetInterval(Value: Int64); // Setter Interval
    procedure SetPriority(Value: TThreadPriority); // Setter Priority
  protected
    { D�clarations prot�g�es }
  public
    { D�clarations publiques }
    constructor Create(AOwner: TComponent); override; // Constructeur
    destructor Destroy; override;  // Destructeur
  published
    { D�clarations publi�es }
    property OnTimer: TNotifyEvent read FOnTimer write SetOnTimer; // Ev�nement OnTimer
    property Enabled: Boolean read FEnabled write SetEnabled; // Propri�t� Enabled
    property Interval: Int64 read FInterval write SetInterval; // Propri�t� Interval
    property Priority: TThreadPriority read FPriority write SetPriority; // Propri�t� Priority
    procedure Timer(Sender: TObject); dynamic; // Proc�dure dynamique qui appelle le gestionnaire de Timer
  end;

  TTimerThrd = class(TThread)
  private
    FEnabled: Boolean; // Champ objet Enabled (strictement identique � celui de TMicroTimer)
    FInterval: Cardinal; // Champ objet Interval (strictement identique � celui de TMicroTimer)
    FTimer: TNotifyEvent; // Pointeur de m�thode vers la proc�dure Timer de TMicroTimer
    procedure CentralControl; // Proc�dure principale
  public
    constructor Create(CreateSuspended: Boolean); // Constructeur du thread
  protected
    procedure Execute; override; // Boucle principale du thread
  end;

procedure Register; // D�claration du recensement du composant

implementation

// Je vais modifier cette fonction pour la rendre plus lisible � moi
// Je cite donc son auteur : Rylryl !!

procedure Wait(MS: int64); // On fait une pause en microsecondes !!
var
 Frq_Base, T_Mem,
 T_Now, Dif: Int64;
begin
 // On r�cup�re l'indice fr�quence du syst�me
 if QueryPerformanceFrequency(Frq_Base) then
  begin
   // On r�cup�re le rep�re temps origine
   QueryPerformanceCounter(T_Mem);
   repeat
   // On r�cup�re le temps actuel
    QueryPerformanceCounter(T_Now);
    // On compare le temps actuel au temps d'origine
    Dif := (T_Now - T_Mem) * 1000000 div Frq_Base;
   until Dif > MS;      // Jusqu'� ce qu'on ai atteint notre d�lai voulu
  end;
end;

procedure Register;  // Recensement du composant
begin
  RegisterComponents('Bacterius', [TMicroTimer]); // On enregistre le composant !
end;

constructor TMicroTimer.Create(AOwner: TComponent);  // Cr�ation du composant
begin
 inherited Create(AOwner); // On cr�e le TComponent qui se cache derri�re mon timer :)
 FInterval := 1000000;   // 1 seconde d'intervalle (h�h� oui c'est en microsecondes !!)
 FEnabled := True;  // On l'active par d�faut
 FThrd := TTimerThrd.Create(True);  // On cr�e le thread
 FThrd.FEnabled := True;  // On fait pareil qu'avec le timer dans le thread
 FThrd.FInterval := 1000000;  // Pareil pour le thread - ultra-important
 FOnTimer := nil;   // M�me chose ...
 FPriority := tpLowest; // Priorit� par d�faut
 FThrd.FTimer := Timer;  // Attention : �a devient interessant :
 // on �tablit un lien entre la proc�dure du thread et celle du timer !
end;

destructor TMicroTimer.Destroy; // Destruction du composant
begin
 FThrd.FEnabled := False; // On arr�te le timer
 FThrd.Suspend; // On arr�te le thread
 FThrd.Terminate; // On �teint le thread
 inherited Destroy; // On d�truit notre composant !
end;

procedure TMicroTimer.Timer(Sender: TObject); // Proc�dure qui appelle le gestionnaire d'�v�nement OnTimer
begin
 if Assigned(FOnTimer) then FOnTimer(self);
 // Si le gestionnaire est assign� alors on l'execute, sinon on ne fait rien !
end;

procedure TMicroTimer.SetOnTimer(Value: TNotifyEvent); // On d�finit le gestionnaire d'�v�nement
begin
 FOnTimer := Value; // On remplace le gestionnaire d'�v�nement par Value
end;

procedure TMicroTimer.SetEnabled(Value: Boolean); // On d�finit l'�tat du timer
begin
 if Value <> FEnabled then // Si l'�tat voulu est diff�rent de celui d'avant
  begin
   FEnabled := Value; // On change
   FThrd.FEnabled := Value;  // On change aussi dans le thread
  end;
end;

procedure TMicroTimer.SetInterval(Value: Int64); // On change l'intervalle du timer
begin
 // On fait Abs(Value) car Int64 est sign�, et un intervalle est toujours positif !
 if Abs(Value) <> FInterval then // Si l'ancien et le nouveau sont diff�rents
  begin
   FInterval := Abs(Value);  // On change
   FThrd.FInterval := Abs(Value);  // On change aussi dans le thread
  end;
end;

procedure TMicroTimer.SetPriority(Value: TThreadPriority); // Setter Priority
begin
 if Value <> FPriority then
  begin
   FThrd.Priority := Value; // Si diff�rent, on change la priorit�
   FPriority := Value; // Idem
  end;
end;

{-------------------------------------------------------------------------------
------------------ FONCTIONS RELATIVES AU THREAD PERIODIQUE --------------------
-------------------------------------------------------------------------------}

constructor TTimerThrd.Create(CreateSuspended: Boolean); // Cr�ation du thread
begin
  inherited Create(CreateSuspended); // On cr�e le thread
  FreeOnTerminate := False; // On le lib�rera nous-m�me c'est plus s�r
  Resume;  // On lance notre thread
  Priority := tpLowest; // Pour �viter que le syst�me ne plante
  // En effet, le syst�me est tellement sollicit� qu'il est capable de perdre le contr�le
  // donc, la plus basse priorit� (et ce n'est pas encore assez !)
end;

procedure TTimerThrd.CentralControl; // Proc�dure principale
begin
 FTimer(self); // On execute la proc�dure qui est cens�e lancer le gestionnaire d'�v�nement
 // En r�alit� on lance une proc�dure qui pointe vers celle cit�e plus haut ^^
end;

procedure TTimerThrd.Execute; // Boucle principale
begin
  repeat  // On r�p�te l'execution du thread ...
    if (not FEnabled) or (csDesigning in Application.ComponentState) then Continue;
    Wait(FInterval); // On attend FInterval �secondes !
    Synchronize(CentralControl);
  until Terminated; // ... jusqu'� ce que le thread soit termin�
end;

end.
 