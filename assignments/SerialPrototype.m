classdef SerialPrototype < Assignment
% SERIAL is a developmental assignment type for debugging Serial without
% actual CV and human agents. It instead uses two Prototype agents.
    
    properties
        policy % n*1 vector which contains the release probability for each class
        humanIndex % index of human agent
        cvIndex % index of CV agent
        batchSize % size of assignment blocks to CV
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
        function A = SerialPrototype(control,batch,policy)
        % SERIAL is the class constructor for assignment type serial. It
        % calls the superclass constructor of Assignment and initializes
        % all necessary properties and listeners.
            A@Assignment(control,'serial');
            A.humanIndex = 2;
            A.cvIndex = 1;
            A.batchSize = batch;
            A.policy = policy;
            A.iterationListener = addlistener(A,'iterationComplete',...
                @A.handleAssignment);
            A.humanUpdateListener = addlistener(A,'humanUpToDate',...
                @A.handleAssignment);
            A.humanAssignment = 0;
            A.humanAssignmentMax = 0;
            A.humanAssignmentTracker = zeros(length(A.control.data),1);
        end
        function handleAssignment(obj,src,event)
        % HANDLEASSIGNMENT handles three different events. When notified by
        % Experiment to start the experiment, it generates an initial
        % assignment to the CV. On subsequent calls from iterationComplete,
        % this is the event for the processing of results from the previous
        % CV assignment, it assigns the next batch of images to the CV. On
        % subsequent calls from humanUpToDate, it completes the experiment
        % if all images have been assigned to the CV.
            if strcmp(event.EventName,'beginExperiment')
                prevIndex = 0;
            else
                prevIndex = find(obj.assignmentMatrix(obj.cvIndex,:),1,'last');
            end
            if size(obj.assignmentMatrix,2) > prevIndex
                if strcmp(event.EventName,'humanUpToDate')
                    return % CV has not yet seen all images
                end
                obj.assignmentMatrix(obj.cvIndex,:) = false;
                try 
                    obj.assignmentMatrix(obj.cvIndex,...
                        (prevIndex+1):(prevIndex+obj.batchSize)) = true;
                catch
                    obj.assignmentMatrix(obj.cvIndex,(prevIndex+1):end) = true;
                end
                assignImages(obj,obj.cvIndex);
            elseif obj.humanAssignment == obj.humanAssignmentMax
                notify(obj.control,'experimentComplete')
            else
                return % Wait for human to be up to date
            end
        end
        function handleResults(obj,src,event)
        % HANDLERESULTS handles two events: classification results from the
        % human or from the CV. These results are populated in Control and
        % trigger distinct calls to handleAssignment through different
        % events.
            fprintf('Results received from %s.\n',src.type);
            if eq(src,obj.control.agents{obj.humanIndex})
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
                    assignImages(obj,obj.humanIndex);
                end
                notify(obj,'iterationComplete');
            end
        end
        function assignment = getHumanAssignment(obj,cvResults)
        % GETHUMANASSIGNMENT assigns a subset of images to the human
        % according to the CV results and policy.
            temp = false(size(cvResults));
            temp(cvResults==-1) = rand(size(temp(cvResults==-1))) < obj.policy(1);
            temp(cvResults==1) = rand(size(temp(cvResults==1))) < obj.policy(2);
            assignment = obj.assignmentMatrix(obj.cvIndex,:);
            assignment(assignment) = temp;
        end
    end
    
end

