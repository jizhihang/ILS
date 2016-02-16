function Y = sml(X)
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
    for i = 1:NumSamples
        indY(i) = all(unique(X(:,i)~=0));
    end
    if length(indY) < length(indX)
        error('Too few samples for the number of agents.')
    end
    Xhat = X(indX,indY);
    [V,~] = eig(Xhat);
    Yhat = sign(V(:,1)'*Xhat);
    
    % Expectation-Maximization
    e = 0.05;
    k = 0;
    flag = false;
    while flag
        psi = zeros(numAgents,1);
        for i = 1:numAgents
            psi(i) = numel(intersect(find(X(i,:)==1),find(Yhat==1)))/...
                numSamples;
        end
        eta = zeros(numAgents,1);
        for i = 1:numAgents
            eta(i) = numel(intersect(find(X(i,:)==-1),find(Yhat==-1)))/...
                numSamples;
        end
        alpha = (psi.*eta)./((1-psi).*(1-eta));
        beta = (psi.*(1-psi))/(eta.*(1-eta));
        Y = sign(log(alpha)'*Xhat+sum(beta));
        k = k+1;
        if norm(Y-Yhat,1) < 2*e*numSamples || k > 50
            flag = true;
        else
            Yhat = Y;
        end
    end

end

