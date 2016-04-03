classdef Human < RemoteAgent
% HUMAN is a child of the LocalAgent superclass. It generates a GUI in
% which the user provides binary classification of images.
    
    properties
        gui % Interface for human user
        response % Classification results from current iteration
        iterationListener % Listener for completion of iteration
    end
    
    events
        iterationComplete % Event triggered by classification of all assigned images in current iteration
    end
    
    methods
        % -----------------------------------------------------------------
        % Class constructor:
        
        function A = Human(remotePort,imageDirectory)
        % HUMAN is the class constructor for the Human remote agent. It
        % initializes an empty GUI, response, and iteration listener.
            if nargin < 1
                error('Too few parameters for class construction.');
            end
            A@RemoteAgent('human',remotePort,imageDirectory);
            A.gui = [];
            A.response = [];
            A.iterationListener = addlistener(A,'iterationComplete',...
                @A.sendResponse);
        end
        
        %------------------------------------------------------------------
        % System-Level:
        
        function classifyImages(obj,src,event)
        % CLASSIFYIMAGES is a callback function which is initiated by the
        % receipt of an image assignment from a local agent. It will
        % classify images or terminate the agent upon receipt of the
        % 'complete' command.
            X = fread(obj.socket,obj.socket.bytesAvailable,'double');
            if strcmp(char(X)','complete')
                terminate(obj);
                close(obj.gui);
                delete(obj.iterationListener);
            elseif strcmp(char(X)','test')
                return
            else
                images = getImages(obj,X); % gets images from directory
                if isempty(obj.gui)
                    obj.gui = human_interface(obj,images,true);
                else
                    human_interface(obj,images,false);
                end
            end
        end
        
        %------------------------------------------------------------------
        % Dependencies:
        
        function sendResponse(obj,src,event)
        % SENDRESPONSE is a function called from the human interface gui
        % that will send the classified image labels back to the control
        % server as soon as the human agent has finished.
            fwrite(obj.socket,obj.response(:),'double');
            fprintf('Human completed classification of %u images.\n',...
                length(obj.response))
            obj.response = [];
        end
        
        %------------------------------------------------------------------
    end
    
end
