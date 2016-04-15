classdef RSVP < RemoteAgent
   
    properties
        gui % Interface for human user
        response % Classification results from current iteration
        iterationListener % Listener for completion of iteration
        sourceType = 'FT'
        rate = 2;
        debugMode = false;
        channels = 1:16;
    end
    
    events
        iterationComplete % Event triggered by classification of all assigned images in current iteration
    end
    
    methods
        % -----------------------------------------------------------------
        % Class constructor:
        
        function A = RSVP(remotePort,imageDirectory,sourceType,rate,debugMode,channels)
            if nargin < 6
                error('Too few parameters for class construction.');
            end
            A@RemoteAgent('RSVP',remotePort,imageDirectory);
            A.gui = [];
            A.response = [];
            A.iterationListener = addlistener(A,'iterationComplete',...
                @A.sendResponse);
            A.gui = [];
            A.sourceType = sourceType;
            A.rate = rate;
            A.channels = channels;
            A.debugMode = debugMode;
            A.gui = rsvp_interface(sourceType, rate, channels, debugMode);
        end
    
        % -----------------------------------------------------------------
        
        %------------------------------------------------------------------
        % System-Level:
        
        function classifyImages(obj,src,event)
        % CLASSIFYIMAGES is a callback function which is initiated by the
        % receipt of an image assignment from a local agent. It will
        % classify images or terminate the agent upon receipt of the
        % 'complete' command.
            X = fread(obj.socket,obj.socket.bytesAvailable,'uint16');
            if strcmp(char(X)','complete')
                terminate(obj);
                delete(obj.iterationListener);
            elseif strcmp(char(X)','test')
                return
            else
                images = getImages(obj,X); % gets images from directory
                init(obj.gui); % init RSVP gui
                obj.response = processImages(obj.gui,images); % run RSVP
                sendResponse(obj);
            end
        end
        
        %------------------------------------------------------------------
        
        %------------------------------------------------------------------
        % Dependencies:
        
        function sendResponse(obj,src,event)
        % SENDRESPONSE is a function called from the human interface gui
        % that will send the classified image labels back to the control
        % server as soon as the human agent has finished.
            fwrite(obj.socket,obj.response(:),'uint8');
            fprintf('RSVP completed classification of %u images.\n',...
                length(obj.response))
            obj.response = [];
        end
        
        %------------------------------------------------------------------
        
    end
end