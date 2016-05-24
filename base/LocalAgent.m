classdef LocalAgent < Agent
% LOCALAGENT is the local agent and a child of the Agent superclass. It
% will open a direct interface connection with the remote agent and send
% assignments and receive classifications from the remote agent.
    
    properties
        socket % Direct interface connection with remote agent
        port % Local port for direct interface connection
    end
    
    events
        resultsReady % Event triggered when results arrive
    end
    
    methods
        %------------------------------------------------------------------
        % Class constructor:
        
        function A = LocalAgent(type,remoteAgentAddress,remoteAgentPort)        
%         function A = LocalAgent(type,remoteAgentAddress,remoteAgentPort,...
%                 ctrl)
        % LOCALAGENT is the class constructor for a local agent. It will
        % create a direct interface object for communication with the
        % remote agent.
            A@Agent(type);
            if nargin < 4
                error('Not enough information to construct HostAgent')
            end
           
            % By not setting a local port the OS will assign a unique and
            % unused port that we can bind to.
            A.socket = UDP(remoteAgentAddress,remoteAgentPort,'InputBufferSize',4096);
            fopen(A.socket);
            
            %Record LocalAgentPort
            A.port = A.socket.LocalPort;
            
            fwrite(A.socket,'LocalAgent: ready','uint16');
            
            fprintf('Reading From %u \n', A.port);
            fprintf('Writing To %u \n', remoteAgentPort);
            
            fprintf('Added a %s agent to port %u.\n',A.type,A.port)
        end
        
        %------------------------------------------------------------------
        % System-level:
        
        function sendImages(obj,X)
        % SENDIMAGES will send image assignments to the remote agent
        % for classification.
            obj.socket.readasyncmode = 'continuous';
            obj.socket.DatagramReceivedFcn = @obj.resultsArrived;
            fwrite(obj.socket,X,'uint16');
        end
        
        function Y = readResults(obj)
        % READRESULTS will retrieve classification results from the remote
        % agent.
            Y = fread(obj.socket,obj.socket.bytesAvailable,'uint8');
            Y(Y==0) = -1;
        end
        
        function terminate(obj)
        % TERMINATE sends a command to a remote agent to close and delete
        % the direct interface socket and then does the same for the local
        % agent.
            fwrite(obj.socket,'complete','uint16');
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
