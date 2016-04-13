function [ v, Aineq, bineq, Aeq, beq ] = convertProblem( V, C, b )
%--------------------------------------------------------------------------
% CONVERTPROBLEM converts a matrix form generalized assignment problem
% (GAP) and converts it into a vector form problem for optimization
% solvers.
% 
% INPUT: 
% V (m x n double)          - Target function for linear problem, max
%                             V(j,:)*x(j,:)
% C (m x n double)          - Inequality (cost) constraint such that
%                             C(j,:)*x(j,:)' <= b(j)
% b (m x 1 double)          - Inequality (budget) constraint such that
%                             C(j,:)*x(j,:)' <= b(j)
% 
% OUTPUT:
% v (mn x 1 double)         - Value of each assignment
% Aineq (m x mn double)     - Inequality constraint (Aineq*x<=bineq) where
%                             m is the number of agents
% bineq (m x 1 double)      - Inequality constraint (Aineq*x<=bineq) where
%                             m is the number of agents
% Aeq (n x mn double)       - Equality constraint (Aeq*x==beq) where n is
%                             the number of tasks
% beq (n x 1 double)        - Equality constraint (Aeq*x==beq) where n is
%                             the number of tasks
% 
% Addison Bohannon
% Iterative Task Assignment System (ITAS)
% 2 November 2015
%--------------------------------------------------------------------------
[m,n] = size(V);

% Value of assignments for GAP
v = V(:);

% Inequality (capacity) constraints for GAP
Aineq = zeros(m,m*n);
for j = 1:m
    Aineq(j,j:m:end) = C(j,:);
end
bineq = b;

% Equality (semi-assignment) constraints for GAP
Aeq = zeros(n,m*n);
for i = 1:n
    Aeq(i,((i-1)*m+1):(i*m)) = ones(1,m);
end
beq = ones(n,1);

end

