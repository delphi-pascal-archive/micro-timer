{------------------------------- MICRO TIMER ----------------------------------
Ce composant s'utilise exactement comme un Timer normal, sauf que l'intervalle
est en microsecondes : donc, 1 => 1 microseconde, 1000 => 1 milliseconde, et
1000000 => 1 seconde.
Code lourdement commenté.
Auteur : Bacterius (thomas.beneteau@yahoo.fr, thomas777@live.fr).

Pour tout Delphi inférieur à Delphi 4 : changez Int64 en Cardinal - pas trop de
conséquences.

--- AVERTISSEMENT ---

Ne mettez pas des tonnes de timers dans une application : 4 MicroTimers,
c'est un maximum !
-------------------------------------------------------------------------------}

unit MicroTimer; // MicroTimer !

interface

uses
  Windows, Messages, SysUtils, Classes, Forms; // Unités requises

type
  TTimerThrd = class; // Classe non définie pour l'instant de TTimerThrd (pour des raisons de compilation)

  TNotifyEvent = procedure(Sender: TObject) of object; // Définition de TNotifyEvent

  TMicroTimer = class(TComponent) // Notre composant Timer !!
  private
    { Déclarations privées }
    FEnabled: Boolean; // Champ objet Enabled
    FInterval: Int64; // Champ objet Interval
    FThrd: TTimerThrd; // Variable du thread timer
    FOnTimer: TNotifyEvent; // Gestionnaire d'évènement OnTimer
    FPriority: TThreadPriority; // Priorité du thread
    procedure SetOnTimer(Value: TNotifyEvent); // Setter OnTimer
    procedure SetEnabled(Value: Boolean);  // Setter Enabled
    procedure SetInterval(Value: Int64); // Setter Interval
    procedure SetPriority(Value: TThreadPriority); // Setter Priority
  protected
    { Déclarations protégées }
  public
    { Déclarations publiques }
    constructor Create(AOwner: TComponent); override; // Constructeur
    destructor Destroy; override;  // Destructeur
  published
    { Déclarations publiées }
    property OnTimer: TNotifyEvent read FOnTimer write SetOnTimer; // Evènement OnTimer
    property Enabled: Boolean read FEnabled write SetEnabled; // Propriété Enabled
    property Interval: Int64 read FInterval write SetInterval; // Propriété Interval
    property Priority: TThreadPriority read FPriority write SetPriority; // Propriété Priority
    procedure Timer(Sender: TObject); dynamic; // Procédure dynamique qui appelle le gestionnaire de Timer
  end;

  TTimerThrd = class(TThread)
  private
    FEnabled: Boolean; // Champ objet Enabled (strictement identique à celui de TMicroTimer)
    FInterval: Cardinal; // Champ objet Interval (strictement identique à celui de TMicroTimer)
    FTimer: TNotifyEvent; // Pointeur de méthode vers la procédure Timer de TMicroTimer
    procedure CentralControl; // Procédure principale
  public
    constructor Create(CreateSuspended: Boolean); // Constructeur du thread
  protected
    procedure Execute; override; // Boucle principale du thread
  end;

procedure Register; // Déclaration du recensement du composant

implementation

// Je vais modifier cette fonction pour la rendre plus lisible à moi
// Je cite donc son auteur : Rylryl !!

procedure Wait(MS: int64); // On fait une pause en microsecondes !!
var
 Frq_Base, T_Mem,
 T_Now, Dif: Int64;
begin
 // On récupère l'indice fréquence du système
 if QueryPerformanceFrequency(Frq_Base) then
  begin
   // On récupère le repère temps origine
   QueryPerformanceCounter(T_Mem);
   repeat
   // On récupère le temps actuel
    QueryPerformanceCounter(T_Now);
    // On compare le temps actuel au temps d'origine
    Dif := (T_Now - T_Mem) * 1000000 div Frq_Base;
   until Dif > MS;      // Jusqu'à ce qu'on ai atteint notre délai voulu
  end;
end;

procedure Register;  // Recensement du composant
begin
  RegisterComponents('Bacterius', [TMicroTimer]); // On enregistre le composant !
end;

constructor TMicroTimer.Create(AOwner: TComponent);  // Création du composant
begin
 inherited Create(AOwner); // On crée le TComponent qui se cache derrière mon timer :)
 FInterval := 1000000;   // 1 seconde d'intervalle (héhé oui c'est en microsecondes !!)
 FEnabled := True;  // On l'active par défaut
 FThrd := TTimerThrd.Create(True);  // On crée le thread
 FThrd.FEnabled := True;  // On fait pareil qu'avec le timer dans le thread
 FThrd.FInterval := 1000000;  // Pareil pour le thread - ultra-important
 FOnTimer := nil;   // Même chose ...
 FPriority := tpLowest; // Priorité par défaut
 FThrd.FTimer := Timer;  // Attention : ça devient interessant :
 // on établit un lien entre la procédure du thread et celle du timer !
end;

destructor TMicroTimer.Destroy; // Destruction du composant
begin
 FThrd.FEnabled := False; // On arrête le timer
 FThrd.Suspend; // On arrête le thread
 FThrd.Terminate; // On éteint le thread
 inherited Destroy; // On détruit notre composant !
end;

procedure TMicroTimer.Timer(Sender: TObject); // Procédure qui appelle le gestionnaire d'évènement OnTimer
begin
 if Assigned(FOnTimer) then FOnTimer(self);
 // Si le gestionnaire est assigné alors on l'execute, sinon on ne fait rien !
end;

procedure TMicroTimer.SetOnTimer(Value: TNotifyEvent); // On définit le gestionnaire d'évènement
begin
 FOnTimer := Value; // On remplace le gestionnaire d'évènement par Value
end;

procedure TMicroTimer.SetEnabled(Value: Boolean); // On définit l'état du timer
begin
 if Value <> FEnabled then // Si l'état voulu est différent de celui d'avant
  begin
   FEnabled := Value; // On change
   FThrd.FEnabled := Value;  // On change aussi dans le thread
  end;
end;

procedure TMicroTimer.SetInterval(Value: Int64); // On change l'intervalle du timer
begin
 // On fait Abs(Value) car Int64 est signé, et un intervalle est toujours positif !
 if Abs(Value) <> FInterval then // Si l'ancien et le nouveau sont différents
  begin
   FInterval := Abs(Value);  // On change
   FThrd.FInterval := Abs(Value);  // On change aussi dans le thread
  end;
end;

procedure TMicroTimer.SetPriority(Value: TThreadPriority); // Setter Priority
begin
 if Value <> FPriority then
  begin
   FThrd.Priority := Value; // Si différent, on change la priorité
   FPriority := Value; // Idem
  end;
end;

{-------------------------------------------------------------------------------
------------------ FONCTIONS RELATIVES AU THREAD PERIODIQUE --------------------
-------------------------------------------------------------------------------}

constructor TTimerThrd.Create(CreateSuspended: Boolean); // Création du thread
begin
  inherited Create(CreateSuspended); // On crée le thread
  FreeOnTerminate := False; // On le libérera nous-même c'est plus sûr
  Resume;  // On lance notre thread
  Priority := tpLowest; // Pour éviter que le système ne plante
  // En effet, le système est tellement sollicité qu'il est capable de perdre le contrôle
  // donc, la plus basse priorité (et ce n'est pas encore assez !)
end;

procedure TTimerThrd.CentralControl; // Procédure principale
begin
 FTimer(self); // On execute la procédure qui est censée lancer le gestionnaire d'évènement
 // En réalité on lance une procédure qui pointe vers celle citée plus haut ^^
end;

procedure TTimerThrd.Execute; // Boucle principale
begin
  repeat  // On répète l'execution du thread ...
    if (not FEnabled) or (csDesigning in Application.ComponentState) then Continue;
    Wait(FInterval); // On attend FInterval µsecondes !
    Synchronize(CentralControl);
  until Terminated; // ... jusqu'à ce que le thread soit terminé
end;

end.
 