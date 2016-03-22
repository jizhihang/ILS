classdef Prototype_CV < RemoteAgent
% PROTOTYPE_CV is a child of the LocalAgent superclass to be used for
% system testing and development. It generates an image classification
% randomly according to a specified accuracy and delay of 1e-2.
    
    properties
        accuracy % Accuracy of prototype agent
        delay % Delay of prototype agent
    end
    
    methods
        % -----------------------------------------------------------------
        % Class constructor:
        
        function A = Prototype_CV(remotePort,agentAccuracy)
            if nargin < 1
                error('Too few parameters for class construction.');
            end
            A@RemoteAgent('prototype_cv',remotePort);
            A.delay = 1e-2;
            if nargin == 2
                A.accuracy = agentAccuracy;
            else
                A.accuracy = rand;
            end
        end
        
        %------------------------------------------------------------------
        % Dependencies:
        
        function Y = classifyImages(obj,src,event)
        % CLASSIFYIMAGES is a callback function which is initiated by the
        % receipt of an image assignment from a local agent. It will
        % classify images or terminate the agent upon receipt of the
        % 'complete' command.
            X = fread(obj.socket);
            if strcmp(char(X)','complete')
                terminate(obj);
            else
                Y = zeros(length(X),1);
                Y(rand(length(X),1)<obj.accuracy) = 1;
                pause(obj.delay);
                fwrite(obj.socket,Y(:));
                fprintf('Prototype_CV completed classification of %u images.\n',...
                    length(X))
            end
        end
        
        %------------------------------------------------------------------
        
    end
    
end