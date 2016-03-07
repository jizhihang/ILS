classdef Serial < Assignment
% SERIAL
    
    properties
        policy % n*1 vector which contains the release probability for each class
        humanIndex % index of human agent
        cvIndex % index of CV agent
        batchSize % size of assignment blocks to CV
        assignmentMatrix % boolean array which tracks assignments to CV and human agents
        iterationListener % listener for iterationComplete event
        humanUpdateListener % listener for humanUpToDate event
        humanAssignment % current assignment iteration awaiting results
        humanAssignmentMax % most recent assignment iteration for human
        humanAssignmentTracker % array of all images assigned to human
    end
    
    events
        iterationComplete % event which signifies the completion of a batch of CV assignments
        humanUpToDate % event which signifies that the human is current with the CV iterations
    end
    
    methods
        function A = Serial(control)
        % SERIAL is the class constructor for assignment type serial. It
        % calls the superclass constructor of Assignment.
            A@Assignment(control,'serial');
%             A.batchSize = input('Enter batch size to send to the CV: ');
%             numClasses = input('Enter the number of unique classes in database: ');
%             A.policy = zeros(numClasses,1);
%             for i = 1:numClasses
%                 A.policy(i) = input(['Enter probability of release to human for class ',i,':']);
%             end
            A.humanIndex = 2;
            A.cvIndex = 1;
            A.batchSize = 2;
            A.policy = [0.5;0.5];
%             for i = 1:length(control.agents)
%                 switch control.agents{i}.type 
%                     case 'human'
%                         A.humanIndex = i;
%                     case 'cv'
%                         A.cvIndex = i;
%                 end
%             end
%             if isempty(A.humanIndex) || isempty(A.cvIndex)
%                 error('Serial policy requires a human and a CV agent.')
%             end
%             if A.humanIndex > 2 || A.cvIndex > 2
%                 error('Too many agents have been added to the sytem.')
%             end
            A.iterationListener = addlistener(A,'iterationComplete',...
                @A.handleAssignment);
            A.humanUpdateListener = addlistener(A,'humanUpToDate',...
                @A.handleAssignment);
            A.assignmentMatrix = false(2,length(A.control.data));
            A.humanAssignment = 0;
            A.humanAssignmentMax = 0;
            A.humanAssignmentTracker = zeros(length(A.control.data),1);
        end
        function handleAssignment(obj,src,event)
        % HANDLEASSIGNMENT
            prevIndex = find(obj.assignmentMatrix(obj.cvIndex,:),1,'last');
            if size(obj.assignmentMatrix,2) > prevIndex
                if strcmp(event.EventName,'humanUpToDate')
                    return
                end
                obj.assignmentMatrix(obj.cvIndex,:) = false;
                try 
                    obj.assignmentMatrix(obj.cvIndex,...
                        prevIndex:(prevIndex+obj.batchSize)) = true;
                catch
                    obj.assignmentMatrix(obj.cvIndex,prevIndex:end) = true;
                end
                assignImages(obj,obj.assignmentMatrix)
            elseif obj.humanAssignment == obj.humanAssigmentMax
                notify(obj.control,'experimentComplete')
            else
                return % Wait for human to be up to date
            end
        end
        function handleResults(obj,src,event)
        % HANDLERESULTS
            fprintf('Results received from %s.\n',src.type);
            if strcmp(src.type,'human')
                obj.humanAssignment = obj.humanAssignment + 1;
                obj.control.results(obj.humanIndex,...
                    obj.humanAssignmentTracker==obj.humanAssignment)...
                    = readResults(src)';
                if obj.humanAssignment == obj.humanAssignmentMax
                    notify(obj,'humanUpToDate');
                end
            else
                results = readResults(src)';
                obj.control.results(obj.cvIndex,...
                obj.assignmentMatrix(obj.cvIndex,:)) = results;
                newAssignment = getHumanAssignment(obj,results);
                if any(newAssignment)
                    obj.humanAssignmentMax = obj.humanAssignmentMax + 1;
                    obj.humanAssignmentTracker(newAssignment)...
                        = obj.humanAssignmentMax;
                    obj.assignmentMatrix(obj.humanIndex,:) = ...
                        obj.humanAssignmentTracker == obj.humanAssignmentMax;
                    obj.assignmentMatrix(obj.cvIndex,:) = false;
                    assignImages(obj,obj.assignmentMatrix);
                end
                notify(obj,'iterationComplete');
            end
        end
        function assignment = getHumanAssignment(obj,cvResults)
        % GETHUMANASSIGNMENT
            temp = false(size(cvResults));
            temp(cvResults==0) = rand(size(cvResults)) < obj.policy(1);
            temp(cvResults==1) = rand(size(cvResults)) < obj.policy(2);
            assignment = obj.assignmentMatrix(obj.cvIndex,:);
            assignment(assignment) = temp;
        end
    end
    
end

