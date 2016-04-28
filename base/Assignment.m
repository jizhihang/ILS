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
        type % Assignment type (options): 'gap', 'all', 'serial','serial_bci'
        assignmentMatrix % boolean matrix which controls assignments to agents
        resultsListener % Listener for resultsReady event
        beginExperimentListener % Listener for beginExperiment
    end
    
    methods
        %------------------------------------------------------------------
        % Class constructor:
        
        function A = Assignment(control,type)
        % ASSIGNMENT is the class constructor for the assignment class.
        % A is an Assignment
        
            A.control = control;
            A.type = type;
            A.assignmentMatrix = false(length(A.control.agents),length(A.control.data));
            A.beginExperimentListener = addlistener(control,...
                'beginExperiment',@A.handleAssignment);
            A.resultsListener = cell(length(A.control.agents),1);
            for i = 1:length(A.control.agents)
                A.resultsListener{i} = addlistener(...
                    A.control.agents{i},'resultsReady',@A.handleResults);
            end
        end
        
        %------------------------------------------------------------------
        % Dependencies:
        
        function assignImages(obj,agent)
        % ASSIGNIMAGES uses an assignmentmatrix (boolean numAgents x
        % numImages) to send image assignments to remote agents.
            if nargin == 2
                sendImages(obj.control.agents{agent},...
                    obj.control.data(obj.assignmentMatrix(agent,:)));
            else
                for i = 1:size(obj.assignmentMatrix,1)
                    if any(obj.assignmentMatrix(i,:))
                        sendImages(obj.control.agents{i},...
                            obj.control.data(obj.assignmentMatrix(i,:)));
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        % System-Level:
        
        function terminate(obj)
        % TERMINATE will delete all listeners in the assignment
            delete(obj.beginExperimentListener);
            for i = 1:length(obj.control.agents)
                delete(obj.resultsListener{i});
            end
        end
        
        %------------------------------------------------------------------
    end
    
    methods (Abstract)
        %------------------------------------------------------------------
        % System-Level:
        
        handleAssignment(obj,src,event)
        % GENERATEASSIGNMENT must also check for experiment completion and
        % notify control
        handleResults(obj,src,event)
        % HANDLERESULTS must also check for iteration completion and call
        % handleassignemnt
        resetAssignment(obj)
        % RESETASSIGNMENT will return assignment to initial state for a
        % follow-on experiment
        
        %------------------------------------------------------------------
    end
    
end

