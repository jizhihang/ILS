classdef Control < handle
% CONTROL contains the local agents and data as well as the assignment
% object and fusion and results properties. It tracks the results and
% manages communication between all agents throughout the experiment. The
% experiment is run through the logic provided by handleAssignment and
% handleResults functions in the assignment object.
    
    properties
        agents % Array of LocalAgent objects
        data % Array of image indices
        assignment % Assignment type (options): 'random', 'gap', 'all', 'serial'
        fusion % Fusion type (options): 'sum', 'sml', 'mv', 'overwrite'
        results % Table of classification results (numAgents x numTrials)
        assignmentResultsReadyListener;
        assignmentCompleteListener;
    end
    
    properties (Dependent)
        labels % Fused classification results (1 x numTrials)
    end
    
    events
        ExperimentCompleteEvent % Event which triggers the end of experiment
        FusionUpdateEvent
    end
    
    methods
        %------------------------------------------------------------------
        % Class constructor:
        
        function C = Control
        % CONTROL is the class constructor. It will create an empty control
        % object. All properties are set from Experiment through control
        % methods.
            C.fusion = '';
            C.assignment = cell(0);
            C.data = [];
            C.agents = cell(0);
            C.results = [];
            C.assignmentResultsReadyListener = [];
            C.assignmentCompleteListener = [];
        end
        
        %------------------------------------------------------------------
        % System-level:
        
        function beginExperiment(obj)
            % TODO change assignment to have a void function.
            event.EventName = 'beginExperiment';
            obj.assignment.handleAssignment(obj, event);
        end
        
        function addAgent(obj, localAgent)
        % ADDAGENT will add a local agent to the agents array by calling
        % the class constructor of local agent and update the size of the
        % results field.
            index = length(obj.agents) + 1;
            obj.agents{index} = localAgent;
            obj.results = zeros(length(obj.agents),length(obj.data));
        end
        
        function addData(obj, newData)
        % ADDDATA will add data to control and update the size of the
        % results field.
            obj.data = [obj.data;newData(:)];
            obj.results = zeros(length(obj.agents),length(obj.data));
        end
        
        function changeAssignment(obj,assignmentType,varargin)
        % CHANGEASSIGNMENT updates the assignment object property
        % Factory method for setting an assignment.
            if ~isempty(obj.assignmentResultsReadyListener)
                delete(obj.assignmentResultsReadyListener);
                obj.assignmentResultsReadyListener = [];
            end
            if ~isempty(obj.assignmentCompleteListener)
                delete(obj.assignmentCompleteListener);
                obj.assignmentCompleteListener = [];
            end
            if ~isempty(obj.assignment)
                terminate(obj.assignment);
            end
            switch assignmentType
                case 'all'
                    obj.assignment = All(obj.agents, obj.data);
                case 'serial'
                    try
                        obj.assignment = Serial(obj.agents, obj.data, ...
                            varargin{1}, varargin{2});
                    catch exception
                        warning(exception)
                        warning('Inappropriate arguments for serial assignment.')
                        obj.assignment = All(obj.agents, obj.data);
                    end
                case 'serial_bci'
                    try
                        obj.assignment = SerialWithBCI(obj.agents, ...
                            obj.data,varargin{1}, varargin{2},varargin{3});
                    catch exception
                        warning(exception)
                        warning('Inappropriate arguments for serial assignment.')
                        obj.assignment = All(obj.agents, obj.data);
                    end
                case 'gap'
                    try
                        obj.assignment = GAP(obj.agents, obj.data, ...
                            varargin{1},varargin{2});
                    catch exception
                        warning(exception)
                        warning('Inappropriate arguments for gap assignment.')
                        obj.assignment = All(obj.agents, obj.data);
                    end
                otherwise
                    warning('Not a valid assignment type. Using all.');
                    obj.assignment = All(obj.agents, obj.data);
            end
            
            obj.assignmentResultsReadyListener = ...
                addlistener(obj.assignment,...
                'AssignmentResultsUpdateEvent',...
                @obj.handleAssignmentResultsReady);
            
            obj.assignmentCompleteListener = ...
                addlistener(obj.assignment,...
                'AssignmentCompleteEvent',...
                @obj.handleAssignmentComplete);
            
        end

        function handleAssignmentResultsReady(obj, src, event)
            obj.results = obj.assignment.results;
            raiseFusionUpdateEvent(obj);
        end
                
        function handleAssignmentComplete(obj, src, event)
            raiseExperimentCompleteEvent(obj);
        end
        
        function terminate(obj)
        % TERMINATE will close and delete the direct interface sockets for
        % all agents in the control object.
            agentIndex = 1:length(obj.agents);
            for i = agentIndex
                terminate(obj.agents{i});
            end
            if ~isempty(obj.assignment)
                terminate(obj.assignment);
            end
        end
        
        %------------------------------------------------------------------
        % Property access:
        
        function Y = get.labels(obj)
        % GET.LABELS is the access command for labels. It will call the
        % given fusion function to determine the pseudo-labels in
        % real-time. Options: 'SML', 'sum', 'MV'.
        %TODO where do we want this to occur
        obj.results = obj.assignment.results;
            switch obj.fusion
                case 'sml'
                    try
                        y = sml(obj.results);
                    catch
                        warning('Something was wrong with SML. Using mv.');
                        temp = obj.results;
                        temp(obj.results==0) = NaN;
                        y = mode(temp,1);
                    end
                case 'sum'
                    temp = obj.results;
                    temp(obj.results==0) = NaN;
                    y = nansum(temp,1);
                    y(y>=0) = 1;
                    y(y<0) = -1;
                case 'mv'
                    % labels are -1 or 1, a zero represents a non-labeled
                    % image. We must change the 0 to NaN otherwise it will
                    % mess up the mv fusion since mode will always return
                    % the smallest value
                    temp = obj.results;
                    temp(obj.results==0) = NaN;
                    y = mode(temp,1);
                case 'overwrite'
                    if any(strcmp(obj.assignment.type,{'serial','serial_bci'}))
                        y = obj.results(obj.assignment.cvIndex,:);
                        temp = obj.results(obj.assignment.humanIndex,:);
                        y(obj.results(obj.assignment.humanIndex,:)~=0) = ...
                            temp(obj.results(obj.assignment.humanIndex,:)~=0);
                    else
                        warning('human_overwrite only works with serial architectures.');
                        temp = obj.results;
                        temp(obj.results==0) = NaN;
                        y = mode(temp,1);
                    end
                otherwise
                    warning('A valid fusion method is not set.');
                    return
            end
            Y = y;
        end
        
        function raiseFusionUpdateEvent(obj)
            notify(obj, 'FusionUpdateEvent');
        end
        
        function raiseExperimentCompleteEvent(obj)
            notify(obj, 'ExperimentCompleteEvent');
        end
        
        %------------------------------------------------------------------
    end
    
end
