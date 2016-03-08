classdef GAP < Assignment
% ALL is an assignment type in which all images are assigned in batch to
% all agents. It results in one iteration.
    
    properties
        iterationStatus % Boolean array which tracks the receipt of classification results
        iterationListener % Listener for iterationComplete event
        agentIndex % Boolean array for referencing agents
        value % numAgents*numImages array of assignment values
        cost % numAgents*numImages array of assignment costs
        budget % numAgents*1 array of budget for each agent for each iteration
        agentReliability % numAgents*1 array of the current reliability estimate
        imageConfidence % numImages*1 array of current confidence in label
        imageCompletion % numImages*1 boolean of completion of images
        threshold % confidence threshold for an image to be complete
    end
    
    events
        iterationComplete % Event which triggers next iteration of assignment
    end
    
    methods
        function A = GAP(control,iterationInterval,confThreshold)
        % ALL is the class constructor for assignment type all. It calls
        % the superclass constructor of assignment and adds a iteration
        % listener.
            A@Assignment(control,'all');
            A.iterationListener = addlistener(A,'iterationComplete',...
                @A.handleAssignment);
            A.agentIndex = false(length(control.agents),1);
            A.value = zeros(size(A.assignmentMatrix));
            A.cost = zeros(size(A.agentIndex));
            for i = 1:length(A.cost)
                switch control.agents{i}.type
                    case 'cv'
                        A.cost(i) = 0.01;
                    case 'human'
                        A.cost(i) = 1;
                    case 'prototype'
                        A.cost(i) = rand;
                    otherwise
                        A.cost(i) = inf;
                end
            end
            A.budget = iterationInterval*ones(size(A.cost));
            A.agentReliability = zeros(size(A.cost));
            A.imageConfidence = zeros(length(control.data),1);
            A.imageCompletion = false(size(A.imageConfidence));
            A.threshold = confThreshold;
        end
        function handleAssignment(obj,src,event)
        % HANDLEASSIGNMENT generates an all true assignment matrix and
        % assigns the images on the first call. When called again, it ends
        % the experiment.
            switch event.EventName
                case 'iterationComplete'
                    getAssignment(obj);
                case 'beginExperiment'
                    obj.assignmentMatrix(:,1:min(25,size(obj.assignmentMatrix,2))) = true;
            end
            assignImages(obj);
        end
        function handleResults(obj,src,event)
        % HANDLERESULTS populates the results table in control as results
        % are ready. When all results are returned, it calls
        % handleAssignment.
            for i = 1:length(obj.control.agents)
                obj.agentIndex(i) = eq(obj.control.agents{i},src);
            end
            obj.control.results(obj.agentIndex,obj.assignmentMatrix(obj.agentIndex,:))...
                = readResults(src)';
            obj.iterationStatus(obj.agentIndex) = true;
            fprintf('Results received from Agent %u.\n',find(obj.agentIndex));
            if all(obj.iterationStatus)
                notify(obj,'iterationComplete');
            end
        end
        function getAssignment(obj)
        % GETASSIGNMENT uses the GAP formulation to generate a new
        % assignmentMatrix.
            [~,score,obj.agentReliability] = sml(obj.control.results);
            obj.imageConfidence = abs(score);
            obj.imageCompletion(obj.imageConfidence>=obj.threshold) = true;
            if all(obj.imageCompletion)
                notify(obj.control,'experimentComplete');
            end
            temp = 1 + repmat(obj.agentReliability,1,size(obj.value,2))...
                - repmat(obj.imageConfidence,size(obj.value,1),1);
            temp(obj.assignmentMatrix) = 0;
            temp(obj.value==0) = 0;
            obj.value = temp;
            numImages = length(find(~obj.imageCompletion));
            numAgents = length(obj.budget);
            [v,Aineq,bineq,Aeq,beq] = convertProblem(...
                obj.value(:,~obj.imageCompletion),...
                repmat(obj.cost,1,numImages),obj.budget);
            intcon = 1:(numAgents*numImages);
            lb = zeros(1,numAgents*numImages);
            ub = ones(1,numAgents*numImages);
            options = optimoptions('intlinprog','Display','none',...
                'CutGeneration','basic');
            tempAssign = intlinprog(-v,intcon,Aineq,bineq,Aeq,beq,...
                lb,ub,options);
            obj.assignmentMatrix(:,~obj.imageCompletion) = reshape(tempAssign,numAgents,numImages);
        end
    end
    
end