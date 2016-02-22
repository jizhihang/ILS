classdef Serial < Assignment
% SERIAL
    
    methods
        function A = Serial(control)
        % SERIAL is the class constructor for assignment type serial. It
        % calls the superclass constructor of Assignment.
            A@Assignment(control,'serial');
        end
        function handleAssignment(obj,src,event)
        % HANDLEASSIGNMENT 
            notify(obj.control,'experimentComplete')               
        end
        function handleResults(obj,src)
        % HANDLERESULTS
            fprintf('Results received from Agent %u.\n',find(index));
            if all(obj.iterationStatus)
                notify(obj,'iterationComplete');
            end
        end
    end
    
end

