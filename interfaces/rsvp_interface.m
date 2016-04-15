classdef rsvp_interface < handle
    properties
        sourceType % signal source type
        rate % rsvp display rate
        trialLen = 1; % lenght of epoch
        channels % channels to analyze
        sourceObj % signal source module
        WHITE               = [255, 255, 255];
        BLACK               = [  0,   0,   0];
        RED                 = [255,   0, 102];
        BLUE                = [102,   0, 255];
        GREEN               = [50,   255, 50];
        BG_COLOR            = [  0,   0,   0];
        
        % ptb specific properties
        escKey
        enterKey
        oldDebugLevel
        screens
        screenNumber
        window
        windowRect
        centX
        centY
        ifi
        refreshRateHz
        stimDuration
        
        debugMode
    end
    
    methods
        %------------------------------------------------------------------
        % Class constructor:
        function self = rsvp_interface(sourceType, rate, channels, debugMode)
            self.sourceType = sourceType;
            self.rate = rate;
            self.channels = channels;
            self.debugMode = debugMode;
            self.stimDuration = 1/rate;
            initialize(self); % initialize rsvp interface
        end
        %------------------------------------------------------------------
        
        %------------------------------------------------------------------
        % Main Functions:
        
        function initialize(self)
        % INITIALIZE starts up the PTB windows, screens and other
        % modules used to run the BCITtempbash
            % initialize Signal Source module
            switch self.sourceType
                case 'FT'
                    self.sourceObj = FT(self.trialLen,1,self.channels,self.debugMode);
                case 'LSL'
                    self.sourceObj = LSL(self.trialLen,1,self.channels,'COM9',self.debugMode);
            end
            
            % initialize Classifier module
            % self.classifierObj = classifier(self)
            
            % initialize PTB
%             init(self);
        end
        
        function init(self)
        % EXP_GENPTBSCREENS generates the main PTB screens used for
        % stimulation and for start and end of experiments.
%             HideCursor;
            KbName('UnifyKeyNames');
            self.escKey = KbName('ESCAPE');
            self.enterKey = KbName('Return');
            self.oldDebugLevel = Screen('Preference', 'VisualDebuglevel', 3);
            self.screens = Screen('Screens');
            self.screenNumber = max(self.screens);
            [self.window, self.windowRect] = Screen('OpenWindow', self.screenNumber, self.BG_COLOR, [], [], 2);
            [self.centX, self.centY] = RectCenter(self.windowRect);
            self.ifi = Screen('GetFlipInterval', self.window);
            self.refreshRateHz = 1/self.ifi;
        end
        
        function results = processImages(self,images)
        % PROCESSIMAGES displays images in a rsvp fashion, extracts the EEG
        % and classifies the epoch
            for i = 1:length(images)
                trialStart = tic;
                imageTexture = Screen('MakeTexture', self.window, images{i});
                Screen('DrawTexture',self.window,imageTexture);
                Screen('Flip',self.window);
                sendTrigger(self.sourceObj,'start');

                % extract trial
                results=ones(1,length(images)); % dummy for now
                % classify previous trial
                results(i) = randi(1);

                while(toc(trialStart) < self.stimDuration)
                    [~, ~, keyCode] = KbCheck;
                    if keyCode(self.escKey), break; end
                end
                sendTrigger(self.sourceObj,'stop');
            end
            % Clear ptb screen
            sca;
        end
        %------------------------------------------------------------------
        
        
    end
end