classdef (Abstract) Agent < handle
% AGENT is the parent class of both LocalAgent and RemoteAgent.
    
    properties
        type % **Options: 'Human', 'RSVP', 'CV'
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
        % Property access:
        
        function t = get.type(obj)
        % GET.TYPE is the external property access function for other
        % objects to query the type of an agent.
            t = obj.type;
        end
        %------------------------------------------------------------------
        
    end
    
end

