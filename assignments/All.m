classdef All < Assignment
% ALL is an assignment type in which all images are assigned in batch to
% all agents. It results in one iteration.
    
    properties
        iterationStatus % Boolean array which tracks the receipt of classification results
%         iterationListener % Listener for iterationComplete event
        agentIndex % Boolean array for referencing agents
        batchSize % size of batch to send to agents
    end
    
    events
%         iterationComplete % Event which triggers next iteration of assignment
    end
    
    methods
        %------------------------------------------------------------------
        % Class constructor:
        
        function A = All(control,batchSize)
        % ALL is the class constructor for assignment type all. It calls
        % the superclass constructor of assignment and adds a iteration
        % listener.
            A@Assignment(control,'all');
%             A.iterationListener = addlistener(A,'iterationComplete',...
%                 @A.handleAssignment);
            A.agentIndex = false(length(control.agents),1);
            if nargin > 1
                A.batchSize = batchSize;
            else
                A.batchSize = min(size(A.assignmentMatrix,2),256);
            end
            numBatches = floor(size(A.assignmentMatrix,2)/A.batchSize);
            if numBatches*A.batchSize < size(A.assignmentMatrix,2)
                numBatches = numBatches + 1;
            end
            A.iterationStatus = repmat(A.agentIndex,1,numBatches);
        end
        
        %------------------------------------------------------------------
        % System-level:
        
        function handleAssignment(obj,src,event)
        % HANDLEASSIGNMENT generates an all true assignment matrix and
        % assigns the images on the first call. When called again, it ends
        % the experiment.
            if strcmp(event.EventName,'beginExperiment')
                obj.assignmentMatrix(:,1:obj.batchSize) = true;
                assignImages(obj);
            else
                error('handleAssignment should not be called from within All.');
            end
        end
        function handleResults(obj,src,event)
        % HANDLERESULTS populates the results table in control as results
        % are ready. When all results are returned, it calls
        % handleAssignment.
            for i = 1:length(obj.control.agents)
                obj.agentIndex(i) = eq(obj.control.agents{i},src);
            end
            currentBatch = find(obj.iterationStatus(obj.agentIndex,:)==false,1,'first');
            if currentBatch == size(obj.iterationStatus,2)
                obj.control.results(obj.agentIndex,...
                    ((currentBatch-1)*obj.batchSize+1):end) = readResults(src)';
            else
                obj.control.results(obj.agentIndex,...
                    ((currentBatch-1)*obj.batchSize+1):(currentBatch*obj.batchSize))...
                    = readResults(src)';
            end
            obj.iterationStatus(obj.agentIndex,currentBatch) = true;
            fprintf('Results received from Agent %u.\n',find(obj.agentIndex));
            if all(obj.iterationStatus(:))
                notify(obj.control,'experimentComplete');
                return
            elseif all(obj.iterationStatus(obj.agentIndex,:))
                return % Wait for the other agents to finish
            else
                obj.assignmentMatrix(obj.agentIndex,:) = false;
                if (currentBatch+1) == size(obj.iterationStatus,2)
                    obj.assignmentMatrix(obj.agentIndex,...
                        (currentBatch*obj.batchSize+1):end) = true;
                else
                    obj.assignmentMatrix(obj.agentIndex,...
                        (currentBatch*obj.batchSize+1):((currentBatch+1)*obj.batchSize))...
                        = true;
                end
                assignImages(obj,find(obj.agentIndex));
            end
        end
%         function terminate(obj)
%         % TERMINATE will delete all listeners in the assignment
%             delete(obj.iterationListener);
%             terminate@Assignment(obj);
%         end
        function resetAssignment(obj)
        % RESETASSIGNMENT will return assignment to initial state for a
        % follow-on experiment
            obj.agentIndex(:) = false;
            obj.iterationStatus(:) = false;
            obj.assignmentMatrix(:) = false;
        end
        
        %------------------------------------------------------------------
    end
    
end