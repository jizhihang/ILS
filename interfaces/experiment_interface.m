function gui = experiment_interface(experiment)
% EXPERIMENT_INTERFACE

    gui = figure('Visible','off','Position',[300,300,500,450]);

    assignmentText = uicontrol('Style','text','String','Assignment',...
        'Position',[100,325,100,50]);
    assignmentMenu = uicontrol('Style','popupmenu','String',{'','all',...
        'gap','serial','serialPrototype'},'Position',[100,300,100,50],...
        'Callback',@assignmentMenu_callback);
	fusionText = uicontrol('Style','text','String','Fusion','Position',...
        [100,225,100,50]);
    fusionMenu = uicontrol('Style','popupmenu','String',...
        {'','sum','mv','sml'},'Position',[100,200,100,50],'Callback',...
        @fusionMenu_callback);
    scanText = uicontrol('Style','text','String','Scanning for Agents',...
        'Position',[300,300,100,50]);
    scanButton = uicontrol('Style','pushbutton','String',...
        'Start Scan','Position',[300,250,100,50],'Callback',...
        @scanButton_callback);
    stopScanButton = uicontrol('Style','pushbutton','String',...
        'Stop Scan','Position',[300,150,100,50],'Callback',...
        @stopScanButton_callback);
	startButton = uicontrol('Style','pushbutton','String','Start',...
        'Position',[100,100,100,50],'Callback',@startButton_callback);
    align([assignmentText,assignmentMenu,fusionText,fusionMenu,...
        startButton],'Left','Distribute');
    
    assignmentText.Units = 'normalized';
    assignmentMenu.Units = 'normalized';
    fusionText.Units = 'normalized';
    fusionMenu.Units = 'normalized';
    scanText.Units = 'normalized';
    scanButton.Units = 'normalized';
    stopScanButton.Units = 'normalized';
    startButton.Units = 'normalized';
    
    gui.Name = 'Experiment';
    movegui(gui,'center')
    gui.Visible = 'on';
    
    function startButton_callback(source,eventdata) 
    % STARTBUTTON_CALLBACK starts the experiment
        addResultsListener(experiment.control.assignment);
        notify(experiment.control,'beginExperiment');
    end

    function scanButton_callback(source,eventdata) 
    % SCANBUTTON_CALLBACK begins scanning for agents
        scanForAgents(experiment);
    end

    function stopScanButton_callback(source,eventdata)
    % STOPSCANBUTTON_CALLBACK ends scanning for agents
        stopScanForAgents(experiment);
    end

    function assignmentMenu_callback(source,eventdata) 
    % ASSIGNMENTMENU_CALLBACK sets the assignment property of the control
    % object
        str = source.String;
        val = source.Value;
        if ~isempty(str{val})
            switch str{val}
                case 'serial'
                    batchSize = input('Enter batch size to send to the CV: ');
                    numClasses = 2;
                    policy = zeros(numClasses,1);
                    for i = 1:numClasses
                        policy(i) = input(['Enter probability of release to human for class ',...
                            num2str(i),':']);
                    end
                    changeAssignment(experiment.control,str{val},batchSize,policy);
                case 'serialPrototype'
                    batchSize = input('Enter batch size to send to the CV: ');
                    numClasses = 2;
                    policy = zeros(numClasses,1);
                    for i = 1:numClasses
                        policy(i) = input(['Enter probability of release to human for class ',...
                            num2str(i),':']);
                    end
                    changeAssignment(experiment.control,str{val},batchSize,policy);
                case 'gap'
                    interval = input('Enter the length of iteration interval in seconds: ');
                    threshold = input('Enter image confidence threshold: ');
                    changeAssignment(experiment.control,str{val},interval,threshold);
                otherwise
                    changeAssignment(experiment.control,str{val});
            end
        end
    end

    function fusionMenu_callback(source,eventdata) 
    % ASSIGNMENTMENU_CALLBACK sets the assignment property of the control
    % object
        str = source.String;
        val = source.Value;
        if ~isempty(str{val})
            experiment.control.fusion = str{val};
        end
    end

end

