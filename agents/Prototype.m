classdef Prototype < RemoteAgent
% PROTOTYPE is a child of the LocalAgent superclass to be used for
% system testing and development. It generates an image classification
% randomly according to a specified accuracy and delay.
    
    properties
        accuracy % Accuracy of prototype agent
        delay % Delay of prototype agent
        trueLabels % True labels of experiment
        trueBehavior % Delay is manifest in agent (boolean)
    end
    
    methods
        % -----------------------------------------------------------------
        % Class constructor:
        
        function P = Prototype(type,remotePort,varargin)
        % PROTOTYPE_HUMAN is the class constructor of the prototype human
        % child class of remote agent. It takes variable name-value pair
        % options: H = Prototype('human',9999, 'accuracy', 0.99,
        % 'trueBehavior', true, 'trueLabels', labels);
            if nargin < 2
                error('Too few parameters for class construction.');
            end
            if ~any(strcmp(type,{'human','rsvp','cv'}))
                error('Not a valid agent type.');
            end
            P@RemoteAgent(type,remotePort);
            switch type
                case 'human'
                    P.delay = 1;
                case 'rsvp'
                    P.delay = 1e-1;
                case 'cv'
                    P.delay = 1e-2;
            end
            P.accuracy = rand;
            P.trueBehavior = false;
            P.trueLabels = [];
            if nargin > 2
                for i = 1:2:length(varargin)
                    switch varargin{i}
                        case 'accuracy'
                            P.accuracy = varargin{i+1};
                        case 'trueBehavior'
                            P.trueBehavior = varargin{i+1};
                        case 'trueLabels'
                            P.trueLabels = varargin{i+1}';
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        % System-Level:
        
        function Y = classifyImages(obj,src,event)
        % CLASSIFYIMAGES is a callback function which is initiated by the
        % receipt of an image assignment from a local agent. It will
        % classify images or terminate the agent upon receipt of the
        % 'complete' command.
            X = fread(obj.socket);
            if strcmp(char(X)','complete')
                terminate(obj);
                return
            elseif strcmp(char(X)','test')
                return
            elseif isempty(obj.trueLabels)
                n = length(X);
                Y = zeros(n,1);
                Y(rand(n,1)<obj.accuracy) = 1;
            else
                n = length(X);
                Y = obj.trueLabels(X);
                index = rand(n,1)>obj.accuracy;
                Y(index) = -Y(index);
            end
            if obj.trueBehavior
                pause(n*obj.delay);
            end
            fwrite(obj.socket,Y(:));
            fprintf('Prototype_Human completed classification of %u images.\n',...
                n)
        end
        
        %------------------------------------------------------------------
        
    end
    
end