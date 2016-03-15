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
    pi = V(:,1);
    score = pi'*X(indX,:);
    label = sign(score);
    pi = abs(pi);
    if length(find(unique(label)~=0)) < 2
        return
    end
    
    % Expectation-Maximization
    e = 0.05;
    k = 0;
    flag = true;
    Yhat = label;
    while flag
        psi = zeros(numAgents,1);
        for i = 1:numAgents
            psi(i) = numel(intersect(find(X(i,:)==1),find(Yhat==1)))/...
                length(find(Yhat~=0));
        end
        eta = zeros(numAgents,1);
        for i = 1:numAgents
            eta(i) = numel(intersect(find(X(i,:)==-1),find(Yhat==-1)))/...
                length(find(Yhat~=0));
        end
        alpha = (psi.*eta)./((1-psi).*(1-eta));
        beta = (psi.*(1-psi))./(eta.*(1-eta));
        tempScore = log(alpha)'*X;
        tempScore(indY) = tempScore(indY) + sum(log(beta));
        tempLabel = sign(tempScore);
        k = k+1;
        if ~all(isfinite(tempScore))
            flag = false;
        elseif norm(label-Yhat,1) < 2*e*numSamples || k > 50
            flag = false;
            pi = abs((psi+eta)/2);
            score = tempScore;
            label = tempLabel;
        else
            Yhat = label;
            pi = abs((psi+eta)/2);
            score = tempScore;
            label = tempLabel;
        end
    end

end

