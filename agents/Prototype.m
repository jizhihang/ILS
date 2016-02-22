classdef Prototype < RemoteAgent
% PROTOTYPE is a child of the LocalAgent superclass to be used for system
% testing and development. It generates an image classification randomly.
    
    properties (Access = private)
        accuracy % Accuracy of prototype agent
    end
    
    methods
        % -----------------------------------------------------------------
        % Class constructor:
        
        function A = Prototype(remotePort)
            if nargin < 1
                error('Too few parameters for class construction.');
            end
            A@RemoteAgent('prototype',remotePort);
            A.accuracy = rand;
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
                Y = -1*ones(length(X),1);
                Y(rand(length(X),1)<obj.accuracy) = 1;
                fwrite(obj.socket,Y(:));
                fprintf('Prototype completed classification of %u images.\n',...
                    length(X))
            end
        end
        
        %------------------------------------------------------------------
        
    end
    
end