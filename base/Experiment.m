classdef Experiment < matlab.mixin.SetGet & handle
% EXPERIMENT creates the environment in which the experiment takes place.
% It will run the experimenter interface, track metrics, establish
% communication with remote agents, and initialize the control.
    
    properties
        LocalPort % Permanent port of local control
        gui % GUI handle
        control % Control object
        socket % Direct interface socket of local control
        listener % Listens for end of experiment notification
        elapsedTime % Elapsed time of experiment
        balAcc % Results of experiment
        numImages % Number of images in database
        testCounter % Counter for automated tests
        assignmentStats % statistics from GAP assignment
        intervalStats % statistics from GAP assignment
        imageStats % confidence statistics from assignment
    end
    
    properties (Access = private)
        labels % Ground truth labels; imported with data and protected from other modules
    end
    
    methods
        %------------------------------------------------------------------
        % Class constructor:
        
        function E = Experiment(images, labels, varargin)
        % EXPERIMENT is the class constructor which will set the data and
        % label properties (not necessary), instantiate a control object,
        % open a GUI, and scan for agents.
        %    EXPERIMENT(X)
        %    EXPERIMENT(X, Y)
        %    EXPERIMENT(X, Y, imageDirectory)
        %    EXPERIMENT(X, Y, P1, V1, ..., PN, VN)
        
            if nargin < 1
                error('Not enough arguments to start an experiment');
            end
            
            % Set Property defaults
            E.LocalPort = 9000; % **Hard-coded**
          
            % Property defaults
            E.labels = [];
            E.assignmentStats = [];
            E.intervalStats = [];
            E.imageStats = [];      
            E.elapsedTime = 0;
            E.balAcc = 0;
            E.testCounter = 0;
            
            % finish setting up the properties with the set command
            if nargin > 1
                E.labels = labels(:);
                if(nargin >= 3)
                    set(E, varargin{1:end});
                end
            end
            
            
            E.control = Control();
            E.control.addData(images);
            E.numImages = length(images);
            % create the other object
            E.listener = addlistener(E.control,'ExperimentCompleteEvent',...
                @E.endExperiment);
           
            E.gui = experiment_interface(E);  
                       
            delete(instrfindall); % delete any existing udp objects
            % Create UDP discovery socket.
            E.socket = UDP('0.0.0.0','LocalPort',E.LocalPort,...
                'InputBufferSize',4096);
            
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
            for i = 1:length(obj.control.agents)
                fwrite(obj.control.agents{i}.socket,'test','uint16');
            end
        end
        
        function beginExperiment(obj)
            obj.control.beginExperiment();
        end
        
        function changeAssignment(obj, varargin)
            obj.control.changeAssignment(varargin);
        end
        
        function setFusion(obj, fusion)
            obj.control.fusion = fusion;
        end
        
        function endExperiment(obj,src,event)
        % ENDEXPERIMENT will end the experiment, shutting down all direct
        % interface connections. It will be initiated by a button on the
        % experimenter interface.
            try
                obj.elapsedTime(end) = toc;
            catch
                warning('Timer not set.');
            end
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
                obj.balAcc(end) = balancedAccuracy(obj.control.labels,...
                    obj.labels);
                fprintf('System achieved %.3f balanced accuracy on %u images in %u seconds.\n',...
                    obj.balAcc(end),obj.numImages,obj.elapsedTime(end));
            else
                fprintf('System classified %u images in %u seconds.\n',...
                    obj.numImages,obj.elapsedTime);
            end
        end
        
        %------------------------------------------------------------------
        % Dependencies:
        
        function newAgent(obj,src,event)
        % NEWAGENT receives the direct interface information from the
        % agent requesting to join the network and passes the information
        % to the ADDAGENT function in the control object.
            type = char(fread(obj.socket,obj.socket.bytesAvailable,'uchar'))';
            remoteHost = event.Data.DatagramAddress;
            remotePort = event.Data.DatagramPort;
            
            obj.createLocalAgentHere(type, remoteHost, remotePort);
        end
        
        function createLocalAgentHere(obj, type, remoteHost, remotePort)
             localAgent = LocalAgent( type, remoteHost, remotePort);            
             obj.control.addAgent(localAgent);
        end
              
        %------------------------------------------------------------------
    end
    
    methods
        function set.LocalPort(obj, val)
            obj.LocalPort = val;
        end
    end
    
end
