classdef Human < RemoteAgent
% HUMAN is a child of the LocalAgent superclass. It generates a GUI in
% which the user provides binary classification of images.
    
    properties
    end
    
    methods
        % -----------------------------------------------------------------
        % Class constructor:
        
        function A = Human(remotePort,imageDirectory)
            if nargin < 1
                error('Too few parameters for class construction.');
            end
            A@RemoteAgent('human',remotePort,imageDirectory);
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
                images = getImages(X); % gets images from directory
                % classify images
                fwrite(obj.socket,Y(:));
                fprintf('Human completed classification of %u images.\n',...
                    length(X))
            end
        end
        
        %------------------------------------------------------------------
        
    end
    
end