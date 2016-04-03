function [YMLE,MLE,PI] = sml(X)
%
% Spectral Meta-Learner
%
% Input:
%   X: a N*S data matrix of N predictors by S instances
%      entries in X are assumed to be +1 or -1
%      (will be converted if real).
%
% Output:
%   PI: balanced accuracy of classifiers
%   MLE: iterative maximum likelihood estimate (starting from HL)
% 
% (c) 2013 Kluger Lab
% modified by Addison Bohannon (01 APR 2016)

 [numAgents,~] = size(X);
 indexSamples = all(X~=0,1);
 if length(indexSamples) < numAgents
     error('Too few samples for the number of agents.')
 end
 Xhat = sign(X(:,indexSamples)');
 [S,~] = size(Xhat);
 CMAT = cov(Xhat);     %computes the covariance
 VMAT = varcov(CMAT,S); %variance  of covariance
        
 %log weighted
 [PI,~] = covadj_weighted(CMAT,VMAT);
 pi_wgs = nanmean(PI);
 if pi_wgs < 0
     PI = -PI;
 end
    
 %spectral-metalearner
 MLE = X'*PI;
 YMLE = sign(MLE);

 %iterative MLE
 [YMLE,MLE,PI] = iMLE(X',YMLE,MLE,PI);
 YMLE = YMLE';
 MLE = MLE';

end

function [ VMAT ] = varcov( CMAT, S )
% for each element in the covariance matrix
%  returns the variance of the mean estimator
% S: datapoints

M = size(CMAT,1);  %algorithms
VMAT = zeros(M);
for i=1:(M-1)
    VMAT(i,i) = 2.*(CMAT(i,i).^2);
    for j=(i+1):M
        VMAT(i,j) = (CMAT(i,i).*CMAT(j,j) + CMAT(i,j).^2)./S;
        VMAT(j,i) = VMAT(i,j);
    end
end

end

function [ R, D, CMAT2 ] = covadj_weighted( CMAT, VMAT )
% thresholded covariance adjustment 
% returns eigenvectors V, eigenvalues D and the adjusted matrix CMAT2
% weights at VMAT

 M  = size(CMAT,1);
 M2 = M.*M; 
 
 CVEC = log(abs(CMAT(:)));
 
 isel = abs(CMAT(:))>0;  %indices of the elements to be used
 
 y = zeros(M2,1);
 x = zeros(M2,M);
 f = zeros(M2,1);
 for i=1:(M-1)
     for j=(i+1):M
         k=i + (j-1).*M;
         if isel(k)==1
             y(k) = CVEC(k);
             x(k,i)=1;
             x(k,j)=1;
             f(k) = (CMAT(i,j).^2)./VMAT(i,j);
         end
     end
 end
 
 y = y(f>0);
 x = x(f>0,:);
 f = f(f>0);
 
 %plot(y)
 b = ones(M,1)*(-Inf);
 i = sum(x)>0;
 b(i) = lscov(x(:,i),y,f);
 
 CMAT2 = CMAT;
 
 for i=1:M
     CMAT2(i,i) = exp(2*b(i));
 end
 
 [R,D] = eigs(CMAT2,1);

end

function [YMLE,MLE,PI] = iMLE( Y, Y0, MLE, PI )
 YBCK = 0.*Y0;
 YMLE = Y0;
 Nsteps = 0;

 [S, M] = size(Y);
 tol = 1 - 1./(S.^2);
 
 psi = zeros(M,1);
 eta = zeros(M,1);
  
 while sum(YBCK~=YMLE)>0 
  Nsteps = Nsteps+1;
  YBCK = YMLE;
  
  for i=1:M
   psi(i) = sum(YMLE>0 & Y(:,i)>0)./sum(YMLE>0);
   eta(i) = sum(YMLE<0 & Y(:,i)<0)./sum(YMLE<0);
  end
  psi = ((tol.* (2 * psi - 1)) + 1)./2;
  eta = ((tol.* (2 * eta - 1)) + 1)./2;  
  psi(isnan(psi)) = 0.5;
  eta(isnan(eta)) = 0.5; 
  PI = 0.5*(psi+eta);
  
  MLE = 0;
  for i=1:M
   MLE = MLE + ( log( (1-Y(:,i))./2 + Y(:,i).*psi(i) ) - ...
                   log( (1+Y(:,i))./2 - Y(:,i).*eta(i) ) );                   
  end
  YMLE = sign(MLE);
 end

end

