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
        agents % list of agents that will be responsible for
        data % list of images to be assigned to the agents
        type % Assignment type (options): 'gap', 'all', 'serial','serial_bci'
        assignmentMatrix % boolean matrix which controls assignments to agents
        results;
        resultsListener % Listener for resultsReady event from agents
    end
    
    events 
        AssignmentResultsUpdateEvent;
        AssignmentCompleteEvent;
    end
    
    methods
        %------------------------------------------------------------------
        % Class constructor:
        
        function A = Assignment(agents, data, type)
        % ASSIGNMENT is the class constructor for the assignment class.
        % A is an Assignment
        % AGENTS - a list of agents that will be responsible for
        % classifying that assigned images
        % DATA - list of images to be assigned to the agents
        % TYPE - type specifying what the assignment algorithm is
            A.agents = agents;
            A.data = data;

            A.type = type;
            A.assignmentMatrix = false(length(A.agents),length(A.data));
            A.resultsListener = cell(length(A.agents),1);
            for i = 1:length(A.agents)
                A.resultsListener{i} = addlistener(...
                    A.agents{i},'resultsReady',@A.handleResults);
            end
        end
        
        %------------------------------------------------------------------
        % Dependencies:
        
        function assignImages(obj,agent)
        % ASSIGNIMAGES uses an assignmentmatrix (boolean numAgents x
        % numImages) to send image assignments to remote agents.
            if nargin == 2
                sendImages(obj.agents{agent},...
                    obj.data(obj.assignmentMatrix(agent,:)));
            else
                for i = 1:size(obj.assignmentMatrix,1)
                    if any(obj.assignmentMatrix(i,:))
                        sendImages(obj.agents{i},...
                            obj.data(obj.assignmentMatrix(i,:)));
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        % System-Level:
        
        function terminate(obj)
        % TERMINATE will delete all listeners in the assignment
            for i = 1:length(obj.agents)
                delete(obj.resultsListener{i});
            end
        end
        
        %------------------------------------------------------------------

        function raiseAssignmentResultsUpdateEvent(obj)
            notify(obj, 'AssignmentResultsUpdateEvent');
        end

        function raiseAssignmentCompleteEvent(obj)
            notify(obj, 'AssignmentCompleteEvent');
        end

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

