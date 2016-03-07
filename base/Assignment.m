classdef (Abstract) Assignment < handle
% ASSIGNMENT is the superclass of all assignment types. It has a connection
% to the control object and specifies the assignment type. Natively, all
% assignments have an assignimage function which takes as an argument a
% boolean assignment matrix of size numAgents by numImages. Additionally,
% all sub-classes must specify functions, handleAssignment and
% handleResults. These are the interface functions for use by the control
% and local agent objects. Additional properties for process management may
% be necessary in subclass (eg. iteration counter, iteraction complete
% event, etc.)
    
    properties
        control % Associated control object
        type % Assignment type (options): 'random', 'gap', 'all', 'serial'
        assignmentMatrix % boolean array which tracks assignments to CV and human agents
        resultsListener % Listener for resultsReady event
        beginExperimentListener % Listener for beginExperiment
    end
    
    methods
        function A = Assignment(control,type)
        % ASSIGNMENT is the class constructor for the assignment class. It
        % will declare 
            A.control = control;
            A.type = type;
            A.assignmentMatrix = false(length(A.control.agents),length(A.control.data));
            A.resultsListener = cell(0);
            A.beginExperimentListener = addlistener(control,...
                'beginExperiment',@A.handleAssignment);
        end
        function addResultsListener(obj)
        % ADDRESULTSLISTENER addes the listener after the agents have been
        % added to the system.
            for i = 1:length(obj.control.agents)
                obj.resultsListener{end+1} = addlistener(...
                    obj.control.agents{i},'resultsReady',@obj.handleResults);
            end
        end
        function assignImages(obj,agent)
        % ASSIGNIMAGES uses an assignmentmatrix (boolean numAgents x
        % numImages) to send image assignments to remote agents.
            if nargin == 2
                sendImages(obj.control.agents{agent},...
                    find(obj.assignmentMatrix(agent,:)));
            else
                for i = 1:size(obj.assignmentMatrix,1)
                    if any(obj.assignmentMatrix(i,:))
                        sendImages(obj.control.agents{i},...
                            find(obj.assignmentMatrix(i,:)));
                    end
                end
            end
        end
        function updateAssignment(obj)
        % UPDATEASSIGNMENT
            A.assignmentMatrix = false(length(obj.control.agents),length(obj.control.data));
        end
    end
    
    methods (Abstract)
        handleAssignment(obj,src,event)
        % GENERATEASSIGNMENT must also check for experiment completion and
        % notify control
        handleResults(obj,src,event)
        % HANDLERESULTS must also check for iteration completion and call
        % handleassignemnt
    end
    
end

