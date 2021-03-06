%% Generate data set

X = 1:200;
Y = [-1*ones(150,1);ones(50,1)];

%% Start experiment

E = Experiment(X,Y);
scanForAgents(E);

%% Set assignment and fusion methods

stopScanForAgents(E);
% E.control.assignment = All(E.control);
E.control.assignment = GAP(E.control,1,2);
% E.control.assignment = GAP(E.control,1,3);
% E.control.assignment = GAP(E.control,1,4);
E.control.fusion = 'sml';

%% Start experiment

autoRun(E,10);

%% ------------------------- Start-up agents ------------------------------

Y = [-1*ones(150,1);ones(50,1)];
A = Prototype('cv',10020,'accuracy',0.75,'trueBehavior',false,'trueLabels',Y);

%%

Y = [-1*ones(150,1);ones(50,1)];
B = Prototype('cv',10021,'accuracy',0.75,'trueBehavior',false,'trueLabels',Y);

%%

Y = [-1*ones(150,1);ones(50,1)];
C = Prototype('rsvp',10022,'accuracy',0.85,'trueBehavior',false,'trueLabels',Y);

%%

Y = [-1*ones(150,1);ones(50,1)];
D = Prototype('rsvp',10023,'accuracy',0.85,'trueBehavior',false,'trueLabels',Y);

%%

Y = [-1*ones(150,1);ones(50,1)];
E = Prototype('human',10024,'accuracy',0.95,'trueBehavior',false,'trueLabels',Y);

%%

Y = [-1*ones(150,1);ones(50,1)];
F = Prototype('human',10025,'accuracy',0.95,'trueBehavior',false,'trueLabels',Y);

