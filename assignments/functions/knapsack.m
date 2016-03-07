function [ x, Z ] = knapsack( v, w, W )
%--------------------------------------------------------------------------
% KNAPSACK uses a dynamic programming algorithm to solve the 0-1 knapsack
% problem. Given n items of specified value and weight and a knapsack
% capacity, the algorithm will determine the maximum value of items to pack
% while not violating the weight capacity. Items can only be assigned once
% or not at all.
% 
% INPUT: 
% v (n x 1 double)          - Value of each of n items
% w (n x 1 double)          - Weight of each of n items (must be
%                             integer-valued)
% W (1 x 1 double)          - Capacity of knapsack (must be integer-valued)
% 
% OUTPUT:
% x (n x 1 double)          - Optimal assignment of items to knapsack (one
%                             - assigned, zero - unassigned)
% Z (m x 1 double)          - Value of optimal assignment for each
%                             subject's knapsack problem
% 
% Addison Bohannon
% Iterative Task Assignment System (ITAS)
% 2 November 2015
%--------------------------------------------------------------------------
if(length(v)~=length(w))
    error('DimMismatch: the dimensions of v and w are inconsistent.');
end

if (sum(round(w)-w)>1e-5) || ((round(W)-W)>1e-5)
   error('IntW: w and W must be integer valued.');
end

if ~((all(w>=0)) && (W>=0))
   error('negW: w and W must be non-negative.');
end

n = length(v); % Number of items
m = zeros(n,W); % Dynamic table of values
s = zeros(n,W); % Dynamic table of assignments
x = zeros(size(v)); % Assignment variable

if W == 0
    Z = 0;
    return;
end

% Populate dynamic tables. The rows of m and s represent the item, 1 to n,
% and the columns represent the weight capacity. It solves the knapsack
% problem with increasing weight capacity, so that the solution to smaller
% problems can be re-used later. m keeps track of the value for the
% sub-problems, and s keeps track of the assignments. For index (i,j), if
% the weight of item i is less than the capacity j, then m(i,j) becomes the
% maximum of m(i-1,j) and m(i-1,j-w(i)) if it were increased by v(i). If
% the latter is greater, then item i is assigned in the sub-problem.
m(1,(1:W>=w(1))) = v(1); % Populate first row for all weight capacities
s(1,(1:W>=w(1))) = 1;
for i = 2:n
    for j = 1:W
        if w(i) < j
            [m(i,j),I] = max([m(i-1,j),m(i-1,j-w(i))+v(i)]);
            if I == 2
                s(i,j) = 1;
            end
        elseif w(i) == j
            [m(i,j),I] = max([m(i-1,j),v(i)]);
            if I == 2
                s(i,j) = 1;
            end
        else
            m(i,j) = m(i-1,j);
        end
    end
end

% Determine optimal packing list from dynamic tables. We begin with full
% capacity and work backward from item n to 1. If item n was assigned in
% column W of m, then assign to optimal packing list and subtract v(n) from
% W, otherwise continue until finding first item assigned. Suppose item n
% was assigned in column W. Then, if item n-1 was assigned in column
% W-v(n), then assign to optimal packing list and subtract v(n-1) from W,
% otherwise continue until finding first item assigned.
K = W;
for i = n:-1:1
    if s(i,K)
        x(i) = 1;
        if w(i) < K
           K = K - w(i);
        else
            break;
        end
    end
end

Z = m(n,W); % Value of optimal packing list

end

