classdef (Abstract) Agent < handle
% AGENT is the parent class of both LocalAgent and RemoteAgent.
    
    properties
        type % **Options: 'human','rsvp','cv'
    end
    
    properties (Abstract)
        socket % Direct interface object between LocalAgent and RemoteAgent
    end
    
    methods
        %------------------------------------------------------------------
        % Class constructor:
        
        function A = Agent(type)
        % AGENT is the base class constructor. The sub-classes will have
        % unique implementations.
            A.type = type;
        end
        
        %------------------------------------------------------------------
        
    end
    
end