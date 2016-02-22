classdef Control < handle
% CONTROL contains the local agents and data. It executes the assignment
% and fusion according to the object properties.
    
    properties
        agents % Array of LocalAgent objects
        data % Array of image indices
        assignment % Assignment type (options): 'random', 'gap', 'all', 'serial'
        fusion % Fusion type (ptions): 'sum', 'sml', 'mv'
        results % Table of classification results (numAgents x numTrials)
    end
    
    properties (Dependent)
        labels % Fused classification results (1 x numTrials)
    end
    
    events
        experimentComplete % Event which triggers the end of experiment
    end
    
    methods
        %------------------------------------------------------------------
        % Class constructor:
        
        function C = Control
        % CONTROL is the class constructor. It will set the assignment and
        % fusion methods.
            C.fusion = 'sum';
            C.assignment = All(C);
            C.data = [];
            C.agents = cell(0);
            C.results = [];
        end
        
        function addAgent(obj,type,localPort,remoteHost,remotePort)
        % ADDAGENT will add a local agent to the agents array by calling
        % the class constructor of LOCALAGENT and update the size of the
        % results field.
            index = length(obj.agents)+1;
            obj.agents{index} = LocalAgent(type,localPort,remoteHost,...
                remotePort,obj);
            updateResults(obj);
        end
        
        function addData(obj,newData)
        % ADDDATA will add data to control and update the size of the
        % results field.
            obj.data = [obj.data;newData(:)];
            updateResults(obj);
        end
        
        function changeAssignment(obj,assignmentType)
        % CHANGEASSIGNMENT updates the assignment object for control
            if ~strcmp(obj.assignment.type,assignmentType)
                delete(obj.assignment);
                switch assignmentType
                    case 'all'
                        obj.assignment = All(obj);
                    case 'random'
                        obj.assignment = Random(obj);
                    case 'serial'
                        obj.assignment = Serial(obj);
                    case 'gap'
                        obj.assignment = GAP(obj);
                    otherwise
                        error('Not a valid assignment type.')
                end
            end
        end
        
        function updateResults(obj)
        % UPDATERESULTS will update the size of the results field according
        % to the current size of agents and data. 
            [n,m] = size(obj.results);
            if n < length(obj.data)
                obj.results(:,(n+1):length(obj.data)) = 0;
            end
            if m < length(obj.agents)
                obj.results((m+1):length(obj.agents),:) = 0;
            end
        end
        
        %------------------------------------------------------------------
        % System-level:
        
        function start(obj)
        % START will populate the results property using the given
        % assignment module
            handleAssignment(obj.assignment);
        end
        
        function terminate(obj)
        % TERMINATE will close and delete the direct interface sockets for
        % all agents in the control object.
            agentIndex = 1:length(obj.agents);
            for i = agentIndex
                terminate(obj.agents{i});
            end
        end
        
        %------------------------------------------------------------------
        % Property access:
        
        function Y = get.labels(obj)
        % GET.LABELS is the access command for labels. It will call the
        % given fusion function to determine the pseudo-labels in
        % real-time. Options: 'SML', 'sum', 'MV'.
            switch obj.fusion
                case 'sml'
                    try
                        y = sml(obj.results);
                    catch
                        warning('Something was wrong with SML. Using sum.');
                        y = sum(obj.results,2);
                    end
                case 'sum'
                    y = sum(obj.results,2);
                case 'mv'
                    y = mode(obj.results,2);
                otherwise
                    error('Not a valid fusion method.');
            end
            Y = y;
        end
        
        %------------------------------------------------------------------
    end
    
end
