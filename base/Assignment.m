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
        resultsListener % Listener for resultsReady event
    end
%     
%     events
%         resultsReady % Event triggered when results arrive
%     end
    
    methods
        function A = Assignment(control,type)
        % ASSIGNMENT is the class constructor for the assignment class. It
        % will declare 
            A.control = control;
            A.type = type;
            A.resultsListener = [];
        end
        function addResultsListener(obj)
        % ADDRESULTSLISTENER addes the listener after the agents have been
        % added to the system.
            obj.resultsListener = addlistener(obj.control.agents{1},...
                'resultsReady',@obj.handleResults);
        end
        function assignImages(obj,assignmentMatrix)
        % ASSIGNIMAGES uses an assignmentmatrix (boolean numAgents x
        % numImages) to send image assignments to remote agents.
            for i = 1:size(assignmentMatrix,1)
                if any(assignmentMatrix(i,:))
                    sendImages(obj.control.agents{i},...
                        find(assignmentMatrix(i,:)));
                end
            end
        end
    end
    
    methods (Abstract)
        handleAssignment(obj)
        % GENERATEASSIGNMENT must also check for experiment completion and
        % notify control
        handleResults(obj,src,event)
        % HANDLERESULTS must also check for iteration completion and call
        % handleassignemnt
    end
    
end

