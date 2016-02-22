classdef All < Assignment
% ALL is an assignment type in which all images are assigned in batch to
% all agents. It results in one iteration.
    
    properties
        iterationStatus % Boolean array which tracks the receipt of classification results
        iterationListener % Listener for iterationComplete event
    end
    
    events
        iterationComplete % Event which triggers next iteration of assignment
    end
    
    methods
        function A = All(control)
        % ALL is the class constructor for assignment type all. It calls
        % the superclass constructor of assignment and adds a iteration
        % listener.
            A@Assignment(control,'all');
            A.iterationListener = addlistener(A,'iterationComplete',...
                @A.handleAssignment);
        end
        function handleAssignment(obj,src,event)
        % HANDLEASSIGNMENT generates an all true assignment matrix and
        % assigns the images on the first call. When called again, it ends
        % the experiment.
            if nargin == 1
                assignmentMatrix = true(length(obj.control.agents),...
                    length(obj.control.data));
                assignImages(obj,assignmentMatrix);
            else
                notify(obj.control,'experimentComplete')
            end                
        end
        function handleResults(obj,src)
        % HANDLERESULTS populates the results table in control as results
        % are ready. When all results are returned, it calls
        % handleAssignment.
            numAgents = length(obj.control.agents);
            index = false(numAgents,1);
            for i = 1:numAgents
                index(i) = eq(obj.control.agents{i},src);
            end
            obj.control.results(index,:) = readResults(src)';
            obj.iterationStatus(index) = true;
            fprintf('Results received from Agent %u.\n',find(index));
            if all(obj.iterationStatus)
                notify(obj,'iterationComplete');
            end
        end
    end
    
end