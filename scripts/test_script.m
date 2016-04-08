%% Generate data set

X = 1:200;
Y = [-1*ones(150,1);ones(50,1)];

%% Start experiment

E = Experiment(X,Y);
scanForAgents(E);

%% Set assignment and fusion methods

stopScanForAgents(E);
E.control.assignment = All(E.control);
% E.control.assignment = GAP(E.control,1,2);
% E.control.assignment = GAP(E.control,1,3);
% E.control.assignment = GAP(E.control,1,4);
E.control.fusion = 'sml';

%% Start experiment

autoRun(E,10);

%% !!!!!!!!!!!-----------change the filename----------------!!!!!!!!!!!!!!!

time = E.elapsedTime;
accuracy = E.balAcc;
confidence = E.imageStats;
if strcmp(E.control.assignment.type,'gap')
    assignments = E.assignmentStats;
    intervals = E.intervalStats;
end
mkdir results
% save('practice.mat','time','accuracy','assignments','intervals','confidence');
save('results\results_all_08APR16.mat','time','accuracy','confidence');
% save('results\results_gap_2_08APR16.mat','time','accuracy','assignments','intervals','confidence');
% save('results\results_gap_3_08APR16.mat','time','accuracy','assignments','intervals','confidence');
% save('results\results_gap_4_08APR16.mat','time','accuracy','assignments','intervals','confidence');

%-------------------------------------------------------------------------
%% Start-up agents

A = Prototype('cv',8000,'accuracy',0.75,'trueBehavior',false,'trueLabels',Y);
% A = Prototype('cv',8000,'accuracy',0.75,'trueBehavior',true,'trueLabels',Y);

%%

B = Prototype('cv',8001,'accuracy',0.75,'trueBehavior',false,'trueLabels',Y);
% B = Prototype('cv',8001,'accuracy',0.75,'trueBehavior',true,'trueLabels',Y);

%%

C = Prototype('rsvp',8002,'accuracy',0.85,'trueBehavior',false,'trueLabels',Y);
% C = Prototype('rsvp',8002,'accuracy',0.85,'trueBehavior',true,'trueLabels',Y);

%%

D = Prototype('rsvp',8003,'accuracy',0.85,'trueBehavior',false,'trueLabels',Y);
% D = Prototype('rsvp',8003,'accuracy',0.85,'trueBehavior',true,'trueLabels',Y);

%%

E = Prototype('human',8004,'accuracy',0.95,'trueBehavior',false,'trueLabels',Y);
% E = Prototype('human',8004,'accuracy',0.95,'trueBehavior',true,'trueLabels',Y);

%%

F = Prototype('human',8005,'accuracy',0.95,'trueBehavior',false,'trueLabels',Y);
% F = Prototype('human',8005,'accuracy',0.95,'trueBehavior',true,'trueLabels',Y);

