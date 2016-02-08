classdef RemoteAgent < Agent
% REMOTEAGENT is the remote agent and a child of the Agent superclass.
% It will receive image classification assignments from the local agent,
% classify the images, and return the results.
    
    properties
        port % Local port of remote agent
        socket % Direct interface communication with local agent
        status % Boolean variable which signifies a connection with the local agent
    end
    
    properties (Access = private)
        accuracy % **set accuracy for development**
    end
    
    methods
        % -----------------------------------------------------------------
        % Class constructor:
        
        function A = RemoteAgent(type,remotePort)
        % REMOTEAGENT is the class constructor for a remote agent. It will
        % be called on a remote host and broadcast its IP address and port
        % to the machine which is hosting the experiment. Upon establishing
        % a connection with the experiment, it will wait for a message from
        % a local agent.
            A@Agent(type);
            A.accuracy = rand();
            A.status = false;
            A.port = remotePort;
            if nargin == 2
                % **This has to be hard-coded for the time being**
                localHost = 'localHost';
                localPort = 2000;
            else
                error('Not enough input arguments to create RemoteAgent.')
            end
            A.socket = udp(localHost,localPort,'LocalHost',...
                'localHost','LocalPort',A.port);
            fopen(A.socket);
            fwrite(A.socket,A.type);
            fclose(A.socket);
            delete(A.socket);
            waitForAgent(A);
        end
        
        %------------------------------------------------------------------
        % System-level:
        
        function start(obj)
        % START moves a remote agent into an on-line status so that it can
        % receive image assignments. It should be called after first
        % establishing a direct interface with the local agent.
            if obj.status
                fopen(obj.socket);
                obj.socket.readasyncmode = 'continuous';
                obj.socket.datagramreceivedfcn = @obj.classifyImages;
            else
                warning('Remote agent is not connected to local agent.')
                return
            end
        end
        
        %------------------------------------------------------------------
        % Dependencies:
        
        function Y = classifyImages(obj,src,event)
        % CLASSIFYIMAGES is a callback function which is initiated by the
        % receipt of an image assignment from a local agent. It will
        % classify images according to the prescribed classification
        % function or terminate the agent upon receipt of the 'complete'
        % command.
            X = fread(obj.socket);
            if strcmp(char(X)','complete')
                terminate(obj);
            else
                Y = -1*ones(1,length(X));
                Y(rand(1,length(X))<obj.accuracy) = 1;
                fwrite(obj.socket,Y);
                fprintf('Agent completed classification of %u images.\n',...
                    length(X))
            end
        end
        
        function waitForAgent(obj)
        % WAITFORAGENT scans all IP broadcasts for an incoming message from
        % the local agent. It calls UPDATESOCKET upon receipt of an
        % incoming message.
            obj.socket = udp('0.0.0.0','LocalHost','localHost',...
                'LocalPort',obj.port);
            fopen(obj.socket);
            obj.socket.readasyncmode = 'continuous';
            obj.socket.datagramreceivedfcn = @obj.updateSocket;
        end
        
        function updateSocket(obj,src,event)
        % UPDATESOCKET creates the direct interface connection with the
        % local agent, sets the status field to true, and starts the remote
        % agent.
            fread(obj.socket);
            fclose(obj.socket);
            delete(obj.socket);
            localHost = event.Data.DatagramAddress;
            localPort = event.Data.DatagramPort;
            obj.socket = udp(localHost,localPort,'LocalHost',...
                'localHost','LocalPort',obj.port);
            obj.status = true;
            fprintf('Agent is connected to the Image Labeling System.\n')
            start(obj)
        end
        
        function terminate(obj)
        % TERMINATE ends the direct interface communication session.
            fclose(obj.socket);
            delete(obj.socket);
            fprintf('Agent terminated.\n')
        end
        
        %------------------------------------------------------------------
    end
    
end

