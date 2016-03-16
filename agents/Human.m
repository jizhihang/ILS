classdef Human < RemoteAgent
% HUMAN is a child of the LocalAgent superclass. It generates a GUI in
% which the user provides binary classification of images.
    
    properties
        gui
        response
        iterationListener
    end
    
    events
        iterationComplete
    end
    
    methods
        % -----------------------------------------------------------------
        % Class constructor:
        
        function A = Human(remotePort,imageDirectory)
            if nargin < 1
                error('Too few parameters for class construction.');
            end
            A@RemoteAgent('human',remotePort,imageDirectory);
            A.gui = cell(0);
            A.response = [];
            A.iterationListener = cell(0);
        end
        
        %------------------------------------------------------------------
        % Dependencies:
        
        function classifyImages(obj,src,event)
        % CLASSIFYIMAGES is a callback function which is initiated by the
        % receipt of an image assignment from a local agent. It will
        % classify images or terminate the agent upon receipt of the
        % 'complete' command.
            X = fread(obj.socket);
            if strcmp(char(X)','complete')
                terminate(obj);
            else
                images = getImages(obj,X); % gets images from directory
                % classify images
                obj.gui = human_interface(obj,images);
                obj.iterationListener = addlistener(obj,...
                    'iterationComplete',@obj.sendResponse);
            end
        end
        
        function sendResponse(obj,src,event)
        % SENDRESPONSE is a function called from the human interface gui
        % that will send the classified image labels back to the control
        % server as soon as the human agent has finished.
%             close(obj.gui);
            fwrite(obj.socket,obj.response(:));
            fprintf('Human completed classification of %u images.\n',...
                length(obj.response))
        end
        %------------------------------------------------------------------
        
    end
    
end
