classdef ArpiExperiment <  % handle
    %ARPIEXPERIMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        numOfAgentsNeeded = 0;
        numOfAgentsConnected = 0;
        network;
        myExperiment;
    end
    
    methods
        
        function obj = ArpiExperiment(discoveryPort)
            % I don't want the superclass constructor because I want to
            % delay setting the images to classify.
            % Use addData(obj.control, images) later
            if(nargin == 0)
                port = 9000;
            else
                port = discoveryPort;
            end
            % set up with a changable discovery port
            obj@Experiment([],[],'LocalPort',port);
%             % TODO Connect to the ARPI network with what paul is working
%             % on
            obj.network = ARPINetwork();
                                     
            addlistener(obj.network, 'NewUserJoinedEvent', @obj.NewUserJoinedEventHandler);
            addlistener(obj.network, 'UserConnectedEvent', @obj.UserConnectedEventHandler);
            addlistener(obj.network, 'MessageReceivedEvent', @obj.MessageReceivedEventHandler);

            obj.network.JoinNetwork(15, ARPINetwork.MakeUID(0, 0));
            
        end
        
        function setImages(obj, imageNamesAsInts, imageLabels)
        % SETIMAGES 
        %   SETIMAGES(IMAGENAMESASINTS) takes a 1xN vector of all the
        %   images that are to be classified.
        %   SETIMAGES(IMAGENAMESASINTS, IMAGELABELS) image names as a 1xN vector of all the
        %   images that are to be classified and a 1xN labels of 1 and 0
        %   that are predefined. this allows it to compute an accuracy as a
        %   test.
           
            obj.numImages = obj.numImages + length(imageNamesAsInts);
            addData(obj.control, imageNamesAsInts);
            
            % IMAGELABELS is optional
            if(~isempty(imageLabels))
                % Check for matching length
                if(length(imageNamesAsInts)~=length(imageLabels))
                    warning('length(IMAGENAMESASINTS) ~= length(IMAGELABELS)');
                end
                obj.imageLabels = [obj.imageLabels imageLabels];
            end
        end
                
        function setNumAgents(obj, num)
            
        end
        
        function setAssignment(obj, assignmentType, varargin)
            %The Image must have been assigned before the assignment can be
            %changed because it uses the assignment matrix to set up the
            %assignment algorithm which is create when image are set.
            if(nargin < 2)
                error('SETASSIGNMENT Not enough args.');
            elseif(nargin == 2)
               obj.control.changeAssignment(assignmentType);
            elseif(nargin > 2)
               obj.control.changeAssignment(assignmentType,varargin(1:end));
            else
                error('SETASSIGNMENT Invalid args.');
            end
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
        
        function newAgent(obj,src,event)
        % NEWAGENT receives the direct interface information from the
        % agent requesting to join the network and passes the information
        % to the ADDAGENT function in the control object.
            newAgent@Experiment(src,event);
%             type = char(fread(obj.DiscoverySocket,obj.DiscoverySocket.bytesAvailable,'uchar'))';
%             remoteHost = event.Data.DatagramAddress;
%             remotePort = event.Data.DatagramPort;
%             addAgent(obj.control,type,remoteHost,...
%                 remotePort);
            
            %TODO CHECK IF ALL AGENTS HAVE BEEN FOUND
            obj.numOfConnectedAgents = obj.numOfConnectedAgents + 1;
        end
        %% Network Functions
        
        function NewUserJoinedEventHandler(obj, src, eventData)
            disp('Mike NewUserJoinedEventHandler');
            disp(eventData);
            
        end
        
        function UserConnectedEventHandler(obj, src, eventData)
            disp('Mike UserConnectedEventHandler');
            disp(eventData);
                        
            src.Subscribe(src.EventData.EventSourceUID, ARPINetwork.ACMPGetMode); %ACMPGetMode
            src.Subscribe(src.EventData.EventSourceUID, ARPINetwork.ACMPSetMode); %ACMPSetMode
            src.Subscribe(src.EventData.EventSourceUID, ARPINetwork.ACMPNotifyMode); %ACMPNotifyMode
            src.Subscribe(src.EventData.EventSourceUID, ARPINetwork.SETILSPARAMETERS); %ACMPNotifyMode

        end
        
        function handleClassificationILSSetup(obj, message)
            disp(message)
        end
        
        function MessageReceivedEventHandler(obj, src, eventData)
            disp('Mike MessageReceivedEventHandler');
            
            switch(eventData.MessageID)
                case ARPINetwork.ACMPGetMode
                    disp('ACMPGetMode Event');
                case ARPINetwork.ACMPSetMode
                    disp('ACMPSetMode Event');
                case ARPINetwork.ACMPNotifyMode
                    disp('ACMPNotifyMode Esavent');                                    
                case ARPINetwork.ClassificationILSSetup
                    disp('Received ClassificationILSSetup Message');
                    obj.handleClassificationILSSetup(eventData)
                otherwise
                    disp('Unknown Event');
            end
        end
    end
end

