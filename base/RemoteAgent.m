classdef (Abstract) RemoteAgent < Agent
% REMOTEAGENT is the remote agent and a child of the Agent superclass.
% It will receive image classification assignments from the local agent,
% classify the images, and return the results.
    
    properties
        imdir % Image directory
        port % Local port of remote agent
        socket % Direct interface communication with local agent
        status % Boolean variable which signifies a connection with the local agent
    end
    
    methods
        % -----------------------------------------------------------------
        % Class constructor:
        
        function A = RemoteAgent(type,imageDirectory)
        % REMOTEAGENT is the class constructor for a remote agent. It will
        % be called on a remote host and broadcast its IP address and port
        % to the machine which is hosting the experiment. Upon establishing
        % a connection with the experiment, it will wait for a message from
        % a local agent.
%             delete(instrfindall); % delete existing udp objects
            A@Agent(type);
            A.status = false;
            if nargin >= 2
                %-----**This has to be hard-coded for the time being**-----
                % TODO change this to a broadcast address.
                discoveryHost = '255.255.255.255'; %We should be able to use 0.0.0.0 now.
                discoveryPort = 9000;
                %----------------------------------------------------------
                if nargin == 3
                    A.imdir = imageDirectory;
                    addpath(A.imdir);
%                     A.imdir = dir(imageDirectory);
%                     A.imdir = A.imdir(3:end);
                else
                    A.imdir = '';
                end
            else
                error('Not enough input arguments to create RemoteAgent.')
            end
            
            A.socket = UDP(discoveryHost, discoveryPort,'InputBufferSize',4096);
            
            fopen(A.socket);
            
            % get the auto assigned port
            A.port = A.socket.LocalPort;
            
            % Set up reply message handler
            A.socket.readasyncmode = 'continuous';
            A.socket.DatagramReceivedFcn = @A.updateSocket;
            
            % Send discovery message
            fwrite(A.socket,A.type,'char');
            
        end
                
        %------------------------------------------------------------------
        % Dependencies:

        function updateSocket(obj,src,event)
        % UPDATESOCKET creates the direct interface connection with the
        % local agent, sets the status field to true, and starts the remote
        % agent.
            % Read to clear datagram received
            disp('update socket')
            fread(obj.socket,obj.socket.bytesAvailable,'uint16');
            
            if nargin > 1
                localAgentAddress = event.Data.DatagramAddress;
                localAgentPort = event.Data.DatagramPort;
            else
                localAgentAddress = obj.socket.DatagramAddress;
                localAgentPort = obj.socket.DatagramPort;
            end           
            
            % Configure the remote address to send to for all future 
            % messages.
            obj.socket.RemoteHost = localAgentAddress;
            obj.socket.RemotePort = localAgentPort;
            
            % Set the status to true as it is ready to receive command
            % message.
            obj.status = true;
            
            fprintf('Agent is connected to the Image Labeling System.\n')
            
            % call start to set up the message handling for the tuntime 
            % message
            start(obj)
        end
                
        %------------------------------------------------------------------
        % System-level:
        
        function start(obj)
        % START moves a remote agent into an on-line status so that it can
        % receive image assignments. It should be called after first
        % establishing a direct interface with the local agent.
            if obj.status
%                 fopen(obj.socket);
                obj.socket.readasyncmode = 'continuous';
                obj.socket.DatagramReceivedFcn = @obj.classifyImages;
            else
                warning('Remote agent is not connected to local agent.')
                return
            end
        end
        
        function terminate(obj)
        % TERMINATE ends the direct interface communication session.
            fclose(obj.socket);
            delete(obj.socket);
            fprintf('Agent terminated.\n')
        end
        
        function imageQueue = getImages(obj,index)
        % GETIMAGE loads an image from the specified directory. It can take
        % a vector argument and will return a cell array of images.
            imageQueue = cell(length(index),1);
            for i = 1:length(index)
                imageQueue{i} = imread(obj.imdir(index(i)).name);
            end
        end
        
        %------------------------------------------------------------------
    end
    
    methods (Abstract)
        %------------------------------------------------------------------
        % System-Level:
        
        classifyImages(obj,src,event)
        
        %------------------------------------------------------------------
    end
    
end
