function [label,score,pi] = sml(X)
% SML takes a matrix of binary classification labels (number of agents by
% number of samples) and uses the spectral meta-learner with
% expectation-maximization to generate a maximum likelihood estimate of the
% true class labels. The EM algorithm terminates when a sufficiently small
% fraction of the labels change between iterations.

    % Spectral Meta-learner
    [numAgents,numSamples] = size(X);
    indX = false(numAgents,1);
    for i = 1:numAgents
        indX(i) = length(unique(X(i,:))) > 1;
    end
    indY = true(numSamples,1);
    for i = 1:numSamples
        indY(i) = all(unique(X(:,i)~=0));
    end
    if length(indY) < length(indX)
        error('Too few samples for the number of agents.')
    end
    Xhat = X(indX,indY);
    Q = cov(Xhat');
    [V,~] = eig(Q);
    Yhat = sign(V(:,1)'*X(indX,:));
    
    % Expectation-Maximization
    e = 0.05;
    k = 0;
    flag = true;
    while flag
        psi = zeros(numAgents,1);
        for i = 1:numAgents
            psi(i) = numel(intersect(find(X(i,:)==1),find(Yhat==1)))/...
                length(Yhat);
        end
        eta = zeros(numAgents,1);
        for i = 1:numAgents
            eta(i) = numel(intersect(find(X(i,:)==-1),find(Yhat==-1)))/...
                length(Yhat);
        end
        alpha = (psi.*eta)./((1-psi).*(1-eta));
        beta = (psi.*(1-psi))/(eta.*(1-eta));
        score = log(alpha)'*X+sum(log(beta));
        label = sign(score);
        k = k+1;
        if norm(label-Yhat,1) < 2*e*numSamples || k > 50
            flag = false;
        else
            Yhat = label;
        end
    end
    pi = (psi+eta)/2;

end

