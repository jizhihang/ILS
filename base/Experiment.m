classdef Experiment < handle
% EXPERIMENT creates the environment in which the experiment takes place.
% It will run the experimenter interface, track metrics, establish
% communication with remote agents, and initialize the control.
    
    properties
        imdir % Directory of image database
        gui % GUI handle
        control % Control object
        localPort % Permanent port of local control
        socket % Direct interface socket of local control
        listener % Listens for end of experiment notification
    end
    
    properties (Access = private)
        labels % Ground truth labels; imported with data and protected from other modules
    end
    
    methods
        %------------------------------------------------------------------
        % Class constructor:
        
        function E = Experiment(X,Y,imageDirectory)
        % EXPERIMENT is the class constructor which will set the data and
        % label properties (not necessary), instantiate a control object,
        % open a GUI, and scan for agents.
            if nargin < 1
                error('Not enough arguments to start an experiment');
            end
            delete(instrfindall); % delete any existing udp objects
            E.localPort = 9000; % **Hard-coded**
            E.control = Control;
            E.socket = udp('0.0.0.0','LocalHost','localHost',...
                'LocalPort',E.localPort);
            E.gui = experiment_interface(E);
            E.listener = addlistener(E.control,'experimentComplete',...
                @E.endExperiment);
            addData(E.control,X);
            if nargin > 1
                E.labels = Y(:);
                if nargin == 3
                    E.imdir = dir(imageDirectory);
                    E.imdir = E.imdir(3:end);
                end
            else
                E.labels = [];
            end
        end
        
        %------------------------------------------------------------------
        % System-level:
        
        function scanForAgents(obj)
        % SCANFORAGENTS scans direct interface communication from any IP
        % address and port. It will open the socket and await messages from
        % remote agents wanting to join the network. It will execute
        % ADDAGENT when an agent requests to join the network.
            fopen(obj.socket);
            obj.socket.DatagramReceivedFcn = @obj.newAgent;
            obj.socket.readasyncmode = 'continuous';
        end
        
        function stopScanForAgents(obj)
        % STOPSCANFORAGENTS closes the direct communication socket to
        % experiment.
            fclose(obj.socket);
        end
        
        function endExperiment(obj,src,event)
        % ENDEXPERIMENT will end the experiment, shutting down all direct
        % interface connections. It will be initiated by a button on the
        % experimenter interface.
            terminate(obj.control);
            delete(obj.listener);
            try
                delete(obj.socket);
            catch
                warning('UDP already closed.');
            end
            try
                close(obj.gui);
            catch
                warning('GUI already closed.');
            end
            fprintf('Experiment complete.\n')
            if ~isempty(obj.labels)
                fprintf('Balanced accuracy: %.3f\n',...
                    balancedAccuracy(obj.control.labels,obj.labels));
            end
        end
        
        %------------------------------------------------------------------
        % Dependencies:
        
        function newAgent(obj,src,event)
        % NEWAGENT receives the direct interface information from the
        % agent requesting to join the network and passes the information
        % to the ADDAGENT function in the control object.
            type = char(fread(obj.socket))';
            uniqueLocalPort = newPort(obj);
            remoteHost = event.Data.DatagramAddress;
            remotePort = event.Data.DatagramPort;
            addAgent(obj.control,type,uniqueLocalPort,remoteHost,...
                remotePort);
        end
        
        function P = newPort(obj)
        % NEWPORT generates an open port on the local server.
            flag = true;
            numAgents = length(obj.control.agents);
            currentPorts = zeros(numAgents+1,1);
            currentPorts(1) = obj.localPort;
            for i = 1:numAgents
                currentPorts(i+1) = obj.control.agents{i}.port;
            end
            while flag
                P = round(1e4*rand);
                if P < 1000
                    P = P + 1000;
                end
                flag = any(currentPorts==P);
            end
        end
        
        %------------------------------------------------------------------
    end
    
end
