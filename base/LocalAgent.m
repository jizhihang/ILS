classdef LocalAgent < Agent
% LOCALAGENT is the local agent and a child of the Agent superclass. It
% will open a direct interface connection with the remote agent and send
% assignments and receive classifications from the remote agent.
    
    properties
        socket % Direct interface connection with remote agent
        port % Local port for direct interface connection
        control % Associated control object
    end
    
    events
        resultsReady % Event triggered when results arrive
    end
    
    methods
        %------------------------------------------------------------------
        % Class constructor:
        
        function A = LocalAgent(type,localPort,remoteHost,remotePort,...
                ctrl)
        % LOCALAGENT is the class constructor for a local agent. It will
        % create a direct interface object for communication with the
        % remote agent.
            A@Agent(type);
            if nargin < 4
                error('Not enough information to construct HostAgent')
            end
            A.port = localPort;
            A.socket = udp(remoteHost,remotePort,'LocalHost',...
                'localHost','LocalPort',A.port);
            A.control = ctrl;
            fopen(A.socket);
            fwrite(A.socket,'LocalAgent: ready');
            fprintf('Added a %s agent to port %u.\n',A.type,A.port)
        end
        
        %------------------------------------------------------------------
        % System-level:
        
        function sendImages(obj,X)
        % SENDIMAGES will send image assignments to the remote agent
        % for classification.
            obj.socket.readasyncmode = 'continuous';
            obj.socket.datagramreceivedfcn = @obj.resultsArrived;
            fwrite(obj.socket,X);
        end
        function Y = readResults(obj)
        % READRESULTS will retrieve classification results from the remote
        % agent.
            Y = fread(obj.socket);
            Y(Y==0) = -1;
        end
        function terminate(obj)
        % TERMINATE sends a command to a remote agent to close and delete
        % the direct interface socket and then does the same for the local
        % agent.
            fwrite(obj.socket,'complete');
            fclose(obj.socket);
            delete(obj.socket);
            fprintf('Agent terminated.\n')
        end
        
        %------------------------------------------------------------------
        % Dependencies:
        
        function resultsArrived(obj,src,event)
        % RESULTSARRIVED calls the handleresults function from the
        % assignment class
            notify(obj,'resultsReady');
        end
        
        %------------------------------------------------------------------
    end
    
end