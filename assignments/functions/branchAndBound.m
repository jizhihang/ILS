function [ X, Z, branches ] = branchAndBound( v, Aineq, bineq,...
    Aeq, beq, varargin )
%--------------------------------------------------------------------------
% BRANCHANDBOUND implements either an exact method or a heuristic greedy
% method for solving the Generalized Assignment Problem (GAP). It
% implements the branch and bound algorithm (Fisher, et al. 1981) to
% exhaustively search the feasible solution space for the optimal solution
% to max(v*x). It uses a best first search method along with a Lagrangian
% Relaxation bounding function.
% 
% INPUT: 
% v (mn x 1 double)         - Value of each assignment
% Aineq (m x mn double)     - Inequality constraint (Aineq*x<=bineq) where
%                             m is the number of inequality constraints
% bineq (m x 1 double)      - Inequality constraint (Aineq*x<=bineq) where
%                             m is the number of inequality constraints
% Aeq (n x mn double)       - Equality constraint (Aeq*x==beq) where n is
%                             the number of equality constraints
% beq (m x 1 double)        - Equality constraint (Aeq*x==beq) where n is
%                             the number of equality constraints
% varargin (string)         - bounding function method
%                             ('multiplierAdjustment', 'subgradient',
%                             'greedy'); can be left blank; default is
%                             'MultiplierAdjustment'
% 
% OUTPUT:
% x (mn x 1 double)         - Optimal assignments
% Z (m x 1 double)          - Maximum bound on problem from dualizing the
%                             equality constraint
% 
% Addison Bohannon
% Iterative Task Assignment System (ITAS)
% 19 November 2015
%--------------------------------------------------------------------------
% Set bounding function for branch and bound algorithm
if nargin > 5
    if strcmp(cell2mat(varargin(1)),'multiplierAdjustment') ||...
            strcmp(cell2mat(varargin(1)),'subgradient') || ...
            strcmp(cell2mat(varargin(1)),'greedy')
        method = cell2mat(varargin(1));
    else
        warning(['Not a valid bounding function: ',cell2mat(varargin(1)),...
            '. Proceeding with multiplierAdjusment method.'])
    end
else
    method = 'subgradient';
end

% Determine problem size
n = size(Aeq,1);
m = size(Aineq,1);

% Initialize Z and X (and branches)
X = []; % X = zeros(size(v)); % Current optimal assignments
Z = 0; % Current optimal assignment value
branches = 0;

% Use bounding function to look for initial solution on entire problem; if
% feasible, then this solution is optimal in GAP. If not feasible, then use
% smallOptimizationProblem to search unassigned tasks to find a nearby
% feasible solution to find feasible X and lower bound for Z. If still
% cannot find a feasible solution. Then unassign each task one-by-one to
% attempt to find a nearby solution. This is computationally costly but
% having a feasible solution before beginning the branch and bound will
% prevent the cost of the algorithm from growing exponentially.
[Xi,~] = bound(v,Aineq,bineq,Aeq,beq,method);
if all(Aeq*Xi == beq) && all(Aineq*Xi <= bineq)
    Z = v'*Xi;
    X = Xi;
    return;
else
    I = find(Aeq*Xi~=beq);
    [Iindex,index] = find(Aeq(I,:)~=0);
    [J,~] = find(Aineq(:,index)~=0);
    k = length(index);
    subAineq = zeros(k,k);
    subBineq = zeros(k,1);
    for j = 1:k
        subAineq(j,:) = Aineq(J(j),index);
        subBineq(j) = bineq(J(j))-Aineq(J(j),:)*Xi;
    end
    subAeq = zeros(k,k);
    subBeq = ones(k,1);
    for i = 1:k
       subAeq(i,:) = Aeq(I(Iindex(i)),index); 
    end
    [Xi(index),~] = smallOptimizationProblem(v(index),subAineq,...
        subBineq,subAeq,subBeq);
    if all(Aeq*Xi == beq) && all(Aineq*Xi <= bineq)
        Z = v'*Xi;
        X = Xi;
    else
        for l = find(Aeq*Xi==beq)'
            Xtemp = Xi;
            Xtemp(Aeq(l,:)~=0)=0;
            I = find(Aeq*Xtemp~=beq);
            [Iindex,index] = find(Aeq(I,:)~=0);
            [J,~] = find(Aineq(:,index)~=0);
            k = length(index);
            subAineq = zeros(k,k);
            subBineq = zeros(k,1);
            for j = 1:k
                subAineq(j,:) = Aineq(J(j),index);
                subBineq(j) = bineq(J(j))-Aineq(J(j),:)*Xtemp;
            end
            subAeq = zeros(k,k);
            subBeq = ones(k,1);
            for i = 1:k
               subAeq(i,:) = Aeq(I(Iindex(i)),index); 
            end
            [Xtemp(index),~] = smallOptimizationProblem(v(index),subAineq,...
                subBineq,subAeq,subBeq);
            if all(Aeq*Xtemp == beq) && all(Aineq*Xtemp <= bineq)
                Ztemp = v'*Xtemp;
                if isempty(Z)
                    Z = Ztemp;
                    X = Xtemp;
                elseif Ztemp > Z
                    Z = Ztemp;
                    X = Xtemp;
                end 
            end
        end
    end
end

% If greedy algorithm is used and if the initial search yielded a feasible
% solution, then return. Else continue with multiplier adjustment method.
if strcmp(method,'greedy') && ~isempty(X)
    return;
else
    method = 'subgradient';
end

% Initialize branch and bound algorithm. Live is a cell array where each
% row corresponds to a unique sub-problem. Live has two columns. The first
% column contains the maximum bound of the sub-problem, and the second
% column contains a 1xn double array, the "assignment" array. The ith entry
% of the "assignment" array denotes the agent to which task i has been
% assigned.
live = {0,zeros(1,n)}; % Live sub-problems in search queue
best = 1; % Index of sub-problem in live with greatest maximum bound

% Branch and bound algorithm. While there are live sub-problems in the
% queue, select the best candidate sub-problem (highest maximum bound). A
% sub-problem will have a subset of the tasks assigned fixed. Once the
% sub-problem is selected, the branches are derived from the first
% unassigned task, one for each agent. Calculate the maximum bound on each
% sub-problem using a bounding function. If the bound is greater than the
% current optimal assignment value, Z, then check for feasibility. If the
% solution is feasible in GAP, then calculate the actual value of the
% assignment solution and if greater than Z, replace Z. If the solution is
% not feasible in GAP, then add to the search queue. If the maximum bound
% is less than the current optimal solution, then "fathom" the solution.
while ~isempty(best)
    
    % Determine unassigned tasks from sub-problem
    assignment = cell2mat(live(best,2));
    I = find(assignment==0);
    
    % Branch on next task for assignment to all possible agents
    for j = 1:m
        
        % Generate new sub-problem
        assignment(I(1)) = j;
        [Xi,remTasks] = getX(assignment,m);
        
        % Bound new sub-problem
        if (bineq - Aineq*Xi) >= 0
            [Xi(remTasks),~] = bound(v(remTasks),Aineq(:,remTasks),...
                bineq - Aineq*Xi,Aeq(I(2:end),remTasks),beq(I(2:end)),...
                method);
            Zi = v'*Xi;

            % If bound is better than best feasible solution thus far, then
            % if feasible, update best feasible solution, otherwise add to
            % queue.
            if Zi > Z
                if all(Aeq*Xi == beq) && all(Aineq*Xi <= bineq)
                    X = Xi;
                    Z = Zi;
                elseif I(1) < (n-1)
                    l = size(live,1)+1;
                    live{l,2} = assignment;
                    live{l,1} = Zi;
                end
                % else Phantom
            end
        end
        
    end
    
    % Select best candidate problem from live for next iteration
    branches = max(branches,size(live,1));
    live(best,:) = [];
    best = findBest(live,Z);
    
end

% In the event that a solution could not be found, the problem is not
% feasible.
if isempty(X)
    error('notFeas: This problem is not feasible.');
end

if branches == 1
    branches = 0;
end

end

function best = findBest( live, Z )
% FINDBEST searches the live problem queue for the sub-problem with the
% greatest maximum bound. The index of the problem is returned unless live
% is empty, then [] is returned.

try
    setZi = cell2mat(live(:,1));
    [Zi,best] = max(setZi);
    if Zi < Z
        best = [];
    end
catch
    best = [];
end

end

function [ X, index ] = getX( Xi, m )
% GETX converts the "assignment" array from live into vector for the
% optimization problem, max(v*X). Additionally, it returns index, a boolean
% array, which identifies the entries of X which have not been fixed by
% previous assignments.

X = zeros(m,length(Xi));
index = true(m,length(Xi));

for i = 1:length(Xi)    
    if Xi(i) ~= 0;
        X(Xi(i),i) = 1;
        index(:,i) = false;
    end
end

X = X(:);
index = index(:);

end

