classdef All < Assignment
% ALL 
    
    properties
        iterationStatus % Boolean array which tracks the receipt of classification results
        iterationListener % Listener for iterationComplete event
    end
    
    events
        iterationComplete % Event which triggers next iteration of assignment
    end
    
    methods
        function A = All(control)
        % ALL is the class constructor for All. It calls the superclass
        % constructor of Assignment.
            A@Assignment(control,'all');
            A.iterationListener = addlistener(A,'iterationComplete',...
                @A.handleAssignment);
        end
        function handleAssignment(obj,src,event)
        % HANDLEASSIGNMENT 
            if nargin == 1
                assignmentMatrix = true(length(obj.control.agents),...
                    length(obj.control.data));
                assignImages(obj,assignmentMatrix);
            else
                notify(obj.control,'experimentComplete')
            end                
        end
        function handleResults(obj,src)
        % HANDLERESULTS
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