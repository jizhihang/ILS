function [ x, Z ] = smallOptimizationProblem( v, Aineq, bineq, Aeq, beq )
%--------------------------------------------------------------------------
% SMALLOPTIMIZATIONPROBLEM solves small linear integer problems, max(v)*x.
% This function will search all possible assignments in order of decreasing
% value, v. If the assignment is feasible, then it will be assigned.
% 
% INPUT: 
% v (n x 1 double)          - Target values where n is the number of
%                             possible assignments
% Aineq (n x n double)      - Inequality constraint such that
%                             Aineq*x <= bineq 
% bineq (n x 1 double)      - Inequality constraint such that
%                             Aineq*x <= bineq
% Aeq (n x n double)        - Equality constraint such that Aeq*x = beq
% beq (n x 1 double)        - Equality constraint such that Aeq*x = beq
% 
% OUTPUT:
% x (n x 1 double)          - Optimal assignment
% Z (1 x 1 double)          - Value of optimal assignment
% 
% Addison Bohannon
% Iterative Task Assignment System (ITAS)
% 2 November 2015
%--------------------------------------------------------------------------

n = length(v); % Size of assignment problem
x = zeros(size(v)); % Assignment variable
Z = 0; % Value of optimal assignment

[~,I] = sort(v,'descend'); % Sort assignments by value

% In order of decreasing assignment value, v(i), check if task i is
% feasible. If so, assign and add to value, Z.
for i = 1:n
    x(I(i)) = 1;
    if all(Aineq(I(i),:)*x <= bineq(I(i))) && all(Aeq(I(i),:)*x == beq(I(i)))
        Z = Z + v(I(i));
    else
        x(I(i)) = 0;
    end
end

end

