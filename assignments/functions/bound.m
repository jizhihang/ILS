function [ x, ZDu ] = bound( v, Aineq, bineq, Aeq, beq, method )
%--------------------------------------------------------------------------
% BOUND provides a maximum bound on max(v*x) for the Generalized Assignment
% Problem (GAP) by dualizing the equality constraints and applying either a
% sub-gradient method or the Multiplier Adjustment Method (Fisher, et al.
% 1986). Upon dualizing the equality constraint, the problem becomes a
% series of efficiently solvable knapsack problems. It can be used in
% conjuction with a branch and bound algorithm to conduct an efficient
% exhaustive search of the solution space.
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
% method (string)           - Bounding function ('subgradient' or
%                             'multiplierAdjustment')
% 
% OUTPUT:
% x (mn x 1 double)         - Optimal assignments
% ZDu (m x 1 double)        - Maximum bound on problem from dualizing the
%                             equality constraint
% 
% Addison Bohannon
% Iterative Task Assignment System (ITAS)
% 19 November 2015
%--------------------------------------------------------------------------
m = size(Aineq,1); % Number of inequality constraints (agents)
n = size(Aeq,1); % Number of equality constraints (tasks)
J = 1:m; % Index of inequality constraints
I = 1:n; % Index of equality constraints
u = zeros(n,1); % Lagrange multipliers
Z = zeros(m,1); % Optimal assignment values for sub-problems, 1 to m
x = zeros(size(v)); % Assignments

% (1) from Fisher, et al. 1986. Initialize the Lagrange multipliers, u, to
% the second largest possible value, v, for each equality constraint
% (task). This initialization guarantees that there will be a Lagrangian
% solution to the knapsack problem in the following section which satisfies
% Aeq*x<=beq.
for i = I
    [V,~] = sort(v(Aeq(i,:)==1),'descend');
    if length(V) > 1
        u(i) = V(2);
    elseif length(V) == 1
        u(i) = V;
    else
        u(i) = 0;
    end
end

% (2) from Fisher, et al. 1986. Solve m knapsack problems, one for each
% inequality constraint (agent), for an initial assignment solution. These
% problems come from dualizing the equality constraint and considering only
% assignments whose values are greater than the Lagrange multiplier.
for j = J
    Ij = find(Aineq(j,:)~=0);
    if ~isempty(Ij)
        Iplus = find(v(Ij)>u);
        if ~isempty(Iplus)
            [x(Ij(Iplus)),Z(j)] = knapsack(v(Ij(Iplus))-u(Iplus),...
                Aineq(j,Ij(Iplus)),bineq(j));
        end
    else
        Z(j) = 0;
    end
end

% Check for feasibility of this solution. If feasible, then this is the
% optimal solution. Proceed to calculating the max bound and return. If not
% feasible, then iterate either sub-gradient descent or the multiplier
% adjustment method until completion.
if Aeq*x==beq
    flag = false;
else
    flag = true;
    switch method
        
        % SUBGRADIENT: Solve knapsack problem with relaxed equality
        % constraints, and then calculate sub-gradient for next step,
        % u(k+1) := u(k) + t*(Aeq*x-beq). Iterate until step size is less
        % than tolerance.
        case 'subgradient'
            Zdu = sum(Z)+sum(u); % Current objective value
            ztol = 1e-3*Zdu; % Tolerance ratio for objective function
            gtol = 1e-4; % Tolerance ratio for gradient
            max_iter = 500; % Maximum iterations for sub-gradient descent
            t = 1; % Initial step size for descent algorithm
            k = 1; % Iteration counter
            
            while flag
                % Calculate sub-gradient and update multiplier; terminate
                % if gradient is sufficiently close to zero
                g = (Aeq*x-beq);
                if t == 1
                    gtol = gtol*norm(g,1);
                end
                if sum(g)^2/t <= gtol || k > max_iter
                    flag = false;
                    continue;
                else
                    u = u + g/t;
                    t = t + 1;
                end
                
                % Solve knapsack problem with updated multipliers
                V = v - Aeq'*u;
                for j = J
                    [x(Aineq(j,:)~=0),Z(j)] = knapsack(V(Aineq(j,:)~=0),...
                            Aineq(j,Aineq(j,:)~=0),bineq(j));
                end
                
                % Decrease step size if objective has plateaued
                if abs(sum(Z)+sum(u)-Zdu) < ztol
                    t = t+100;
                end
                Zdu = sum(Z)+sum(u);
                k = k + 1;
                
            end
            
        % MULTIPLIERADJUSTMENT: Re-solve the knapsack problems including
        % those assignments whose values are equal to the Lagrange
        % multipliers, check for feasibility, decrease the Lagrange
        % multiplier for a task which is not yet assigned and assign it,
        % and re-solve the corresponding knapsack problem for the agent who
        % incurred that assignment.
        case 'multiplierAdjustment'
            while flag
                % Update multipliers according to the multiplier adjustment
                % method
                [tempX,tempZ,tempU,flag] = adjustMultiplier(x,Z,u,v,...
                    Aineq,bineq,Aeq,beq);
                if (sum(tempU)+sum(tempZ)) < (sum(u)+sum(Z))
                    x = tempX;
                    Z = tempZ;
                    u = tempU;
                else
                    flag = false;
                end
            end
    end
end

% Calculate maximum bound and return. Maximum bound is the sum of all
% Lagrange multipliers and knapsack solutions.
ZDu = u'*beq + sum(Z);

end