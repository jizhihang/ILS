classdef Control < handle
% CONTROL contains the local agents and data. It executes the assignment
% and fusion according to the object properties.
    
    properties
        agents % Array of LocalAgent objects
        data % **Not sure how to handle this yet: maybe path and indices**
        assignment % **Options: 'random', 'GAP', etc.**
        fusion % **Options: 'sum', 'sml', 'mv', etc.**
    end
    
    properties (Access = private)
        results % Table of classification results (numAgents x numTrials)
        flag % Boolean array which tracks assignment completion (numAgents x 1)
    end
    
    properties (Dependent)
        labels % Fused classification results (1 x numTrials)
    end
    
    events
        complete % Event which triggers the end of experiment
    end
    
    methods
        %------------------------------------------------------------------
        % Class constructor:
        
        function C = Control(assignmentMethod,fusionMethod)
        % CONTROL is the class constructor. It will set the assignment and
        % fusion methods.
            C.fusion = 'sum';
            C.assignment = 'all';
            if nargin >= 1
                C.assignment = assignmentMethod;
                if nargin == 2
                    C.fusion = fusionMethod;
                end
            end
            C.data = [];
            C.agents = cell(0);
            C.results = [];
            C.flag = false(0);
        end
        
        function addAgent(obj,type,localPort,remoteHost,remotePort)
        % ADDAGENT will add a local agent to the agents array by calling
        % the class constructor of LOCALAGENT and update the size of the
        % results field.
            index = length(obj.agents)+1;
            obj.agents{index} = LocalAgent(type,localPort,remoteHost,...
                remotePort,obj);
            obj.flag{index} = false;
            updateResults(obj);
        end
        
        function addData(obj,newData)
        % ADDDATA will add data to control and update the size of the
        % results field.
            obj.data = [obj.data;newData(:)];
            updateResults(obj);
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
        
        function run(obj)
        % RUN will populate the results table using the given assignment
        % method. Options: 'all'.
            switch obj.assignment
                case 'all'
                    agentIndex = 1:length(obj.agents);
                    listener = cell(length(obj.agents),1);
                    obj.flag(:) = false;
                    for i = agentIndex
                        listener{i} = addlistener(obj.agents{i},...
                            'classificationComplete',...
                            @obj.getResults);
                        assignImages(obj.agents{i},obj.data);
                    end
                otherwise
                    error('Not a valid option for assignment.')
            end
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
                case 'SML'
                    error('Sorry, not ready yet.')
                case 'sum'
                    y = sum(obj.results,2);
                case 'MV'
                    y = mode(obj.results,2);
                otherwise
                    error('Not a valid fusion method.');
            end
            Y = y;
        end
        
        %------------------------------------------------------------------
        % Dependencies:
        
        function getResults(obj,src,event)
        % GETRESULTS retrieves the classification results following
        % assignment in the RUN method. It works in conjuction with RUN to
        % populate the results table.
            switch obj.assignment
                case 'all'
                    index = false(length(obj.agents),1);
                    for i = 1:length(obj.agents)
                        index(i) = eq(obj.agents{i},src);
                    end
                    obj.results(index,:) = getResults(src)';
                    obj.flag(index) = true;
                    fprintf('Results received from Agent %u.\n',find(index));
                    if all(obj.flag)
                        notify(obj,'complete');
                    end
                otherwise
                    error('Not a valid assignment policy.');
            end
        end
        
        %------------------------------------------------------------------
    end
    
end