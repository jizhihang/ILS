function [ x, Z, u, flag ] = adjustMultiplier( x, Z, u, v, Aineq,...
    bineq, Aeq, beq )
%--------------------------------------------------------------------------
% ADJUSTMULTIPLIER implements the iterative portion of the Multiplier
% Adjustment Method (Fisher, et al. 1986). Each time it executes, it will
% attempt to lower the overall bound, ZDu, of the Lagrangian Relaxation
% problem. It will heuristically choose to decrease one Lagrange Multiplier
% during each iteration to achieve a better bound and return that optimal
% solution and bound along with the Lagrange multipliers. If a feasible
% solution is found, then flag is returned false to indicate to the
% bounding function that a overall optimal solution is being returned.
% 
% INPUT: 
% x (mn x 1 double)         - Current optimal assignments
% Z (m x 1 double)          - Current optimal assignment value for each
%                             of m knapsack problems
% u (n x 1 double)          - Current Lagrange multipliers where n is the
%                             number of equality constraints
% v (mn x 1 double)         - Value of each assignment
% Aineq (m x mn double)     - Inequality constraint (Aineq*x<=bineq) where
%                             m is the number of inequality constraints
% bineq (m x 1 double)      - Inequality constraint (Aineq*x<=bineq) where
%                             m is the number of inequality constraints
% Aeq (n x mn double)       - Equality constraint (Aeq*x==beq) where n is
%                             the number of equality constraints
% beq (m x 1 double)        - Equality constraint (Aeq*x==beq) where n is
%                             the number of equality constraints
% 
% OUTPUT:
% x (mn x 1 double)         - Updated optimal assignment
% Z (m x 1 double)          - Updated optimal assignment value for each
%                             of m knapsack problems
% u (n x 1 double)          - Updated Lagrange multipliers where n is the
%                             number of equality constraints
% flag (1 x 1 logical)      - Indicates to calling function whether to
%                             continue iterating (false - feasible solution
%                             found)
% 
% Addison Bohannon
% Iterative Task Assignment System (ITAS)
% 4 November 2015
%--------------------------------------------------------------------------
m = size(Aineq,1); % Number of inequality constraints (agents)
n = size(Aeq,1); % Number of equality constraints (tasks)
J = 1:m; % Index of agents
I = 1:n; % Index of tasks
flag = true;

% (3) from Fisher, et al. 1986. For all remaining unassigned tasks, take
% all possible assignments which have a value equal to the corresponding
% Lagrange multiplier. With this set, find an optimal assignment of tasks
% which will not violate the capacity or semi-assignment constraints.

% (3)(a) Identify all unassigned tasks and update capacity constraints
Ibar = find(Aeq*x~=beq)';
bbar = bineq - Aineq*x;

% (3)(b) Identify all possible assignments of those unassigned tasks which
% have a value equal to the corresponding Lagrange multiplier
Ji0 = [];
Ij0 = [];
f = [];
index = [];
for i = Ibar
   Ji = find(Aeq(i,:)~=0);
   temp = find(v(Ji)==u(i));
   if ~isempty(temp)
       index = [index,Ji(temp)];
       Ji0 = [Ji0,temp];
       Ij0 = [Ij0,i*ones(size(temp))];
       f = [f;u(i)*ones(size(temp))'];
   end
end
k = length(f);

% (3)(c) Set-up optimization sub-problem
subAineq = zeros(k,k);
subBineq = zeros(k,1);
for j = 1:k
    Ij = find(Aineq(Ji0(j),:)~=0);
    subAineq(j,:) = Aineq(Ji0(j),Ij(Ij0));
    subBineq(j) = bbar(Ji0(j));
end
subAeq = zeros(k,k);
subBeq = ones(k,1);
for i = 1:k
   subAeq(i,Ij0==Ij0(i)) = 1; 
end

% (3)(d) Update optimal assignment by solving optimization sub-problem
[x(index),~] = smallOptimizationProblem(f,subAineq,subBineq,subAeq,subBeq);
for j = 1:length(Ji0)
   Z(Ji0(j)) = Z(Ji0(j)) + x(index(j))*v(index(j));
end

% (4) from Fisher, et al. 1986. For all unassigned tasks, calculate the
% least decrease, d(j,i), in the corresponding Lagrange multiplier, u(i) in
% order for an item, i, to be included in an optimal solution. Then, find
% all tasks which are unassigned and whose second smallest least decrease,
% min2(d(:,i)), is positive.

% (4)(a) Check for feasibility of current optimal solution. If feasible,
% then update flag and return.
Iua = find(Aeq*x~=beq);
if isempty(Iua)
    flag = false;
    return;
end
k = length(Iua);
D = zeros(m,k);

% (4)(b) Calculate the least decrease, D(j,i), in the corresponding
% Lagrange multiplier, u(i) in order for an item, i, to be included in an
% optimal solution. The formula is as follows: D(j,i) = Z(j)-v(j,i)+u(i)-Y,
% where Y=max((v(j,:)-u(i))*x(j,:)) over all tasks except i.
for i = 1:k
    Iminus = find(I~=Iua(i));
    for j = J
        Ij = find(Aineq(j,:)~=0);
        if (bineq(j) > Aineq(j,Ij(Iua(i)-(n-length(Ij))))) && (~isempty(Ij)) && (~isempty(Iminus))
            [~,Y] = knapsack(v(Ij(Iminus))-u(Iminus),...
                Aineq(j,Ij(Iminus)),bineq(j)-Aineq(j,Ij(Iua(i))));
            D(j,i) = Z(j) - v(Ij(Iua(i))) + u(Iua(i)) - Y;
        else
            D(j,i) = -inf;
        end
    end
end

% (4)(c) Find all tasks which are still unassigned and with min2(D(:,i))
% positive.
I0 = [];
dIndex = [];
for i = 1:k
    [~,index] = sort(D(:,i),'ascend');
    if D(index(2),i)>0
        I0 = [I0;Iua(i)];
        dIndex = [dIndex,i];
    end
end

% (5) from Fisher, et al. 1986. Select an unassigned task, i, from I0 and
% decrease the corresponding Lagrange multiplier by min2(D(:,i)). Then
% choose the agent, j, for which argmin(D(:,i))=j. Assign task i to agent
% j, and solve a knapsack problem for agent j with the updated Lagrange
% multiplier. If the solution is feasible, then return. The bound has been
% decreased. Otherwise, continue to search I0 until exhausted.

% (5)(a) If there are no such assignments that can be found by reducing the
% Lagrange multipliers, then update the flag and return the current optimal
% solution.
k = length(I0);
if k == 0
    flag = false;
    return;
end

% (5)(b) Select an unassigned task, i, from I0 and decrease the
% corresponding Lagrange multiplier by min2(D(:,i)). Then choose the agent,
% j, for which argmin(D(:,i))=j. Assign task i to agent j, and solve a
% knapsack problem for agent j with the updated Lagrange multiplier.
for i = randperm(k)
    % For I0(i), decrease u(i) by min2(d(:,i)) and select j=argmin(D(:,i))
    [~,index] = sort(D(:,dIndex(i)),'ascend');
    tempU = u(I0(i));
    u(I0(i)) = u(I0(i)) - D(index(2),dIndex(i));
    Iminus = intersect(find(I~=I0(i)),find(beq~=0));
    j = index(1);
    
    % Set-up knapsack problem and ensure feasibility. Set x(j,i)=1, and
    % solve knapsack problem j. If solution is semi-feasible, then return.
    % If solution is not feasible in GAP, then reset and choose another
    % task i and iterate until I0 is exhausted.
    Ij = find(Aineq(j,:)~=0);
    x(Ij(I0(i))) = 1;
    tempX = x;
    tempZ = Z;
    if bineq(j) > Aineq(j,Ij(I0(i)))
        [x(Ij(Iminus)),Z(j)] = knapsack(v(Ij(Iminus))-u(Iminus),...
            Aineq(j,Ij(Iminus)),bineq(j)-Aineq(j,Ij(I0(i))));
        if Aeq*x <= 1
            return;
        else
            x = tempX;
            Z = tempZ;
            u(I0(i)) = tempU;
        end
    else
        x = tempX;
        Z = tempZ;
        u(I0(i)) = tempU;
    end
end

end

