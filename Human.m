classdef Human < RemoteAgent
% HUMAN is a child of the LocalAgent superclass. It generates a GUI in
% which the user provides binary classification of images.
    
    properties
        hGui % structure for holding the gui handles
        hFigure % handle to gui figure
        pred_labels
    end
    
    methods
        % -----------------------------------------------------------------
        % Class constructor:
        
        function A = Human(remotePort,imageDirectory)
            if nargin < 1
                error('Too few parameters for class construction.');
            end
            A@RemoteAgent('human',remotePort,imageDirectory);
            
            % create Labeling interface for human agent
            [A.hFigure, A.hGui] = human_interface;
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
                images = getImages(obj,X); % gets images from directory
                
                % classify images
                human_interface('displayImages',obj.hGui,1,images,obj);  % show image to user
            end
        end
        
        
        function sendImageLabels(obj,labels)
        % SENTIMAGELABELS is a function called from the human interface gui
        % that will send the classified image labels back to the control
        % server as soon as the human agent has finished.
            fwrite(obj.socket,labels(:));
            fprintf('Human completed classification of %u images.\n',...
                length(labels))
        end
        %------------------------------------------------------------------
        
    end
    
end
