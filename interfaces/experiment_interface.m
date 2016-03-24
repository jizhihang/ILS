function gui = experiment_interface(experiment)
% EXPERIMENT_INTERFACE
    gui = figure('Visible','off','Position',[300,300,500,450]);
    infoText = uicontrol('Style','text','String','Select "Start Scan".',...
        'Position',[0 375 500 50],'FontSize',14);
    panel = uipanel('Position',[0.15 0.15 0.7 0.7]);
    assignmentText = uicontrol('Style','text','String','Assignment',...
        'Position',[100,305,100,50],'TooltipString',...
        'Select Assignment method (this is done after remote agents are connected).');
    assignmentMenu = uicontrol('Style','popupmenu','String',{'','all',...
        'gap','serial','serial_bcis'},'Position',[100,300,100,50],...
        'Callback',@assignmentMenu_callback,'TooltipString',...
        'Select Assignment method (this is done after remote agents are connected).');
	fusionText = uicontrol('Style','text','String','Fusion','Position',...
        [100,205,100,50],'TooltipString',...
        'Select Fusion method (this is done after remote agents are connected).');
    fusionMenu = uicontrol('Style','popupmenu','String',...
        {'','sum','mv','sml'},'Position',[100,200,100,50],'Callback',...
        @fusionMenu_callback,'TooltipString',...
        'Select Fusion method (this is done after remote agents are connected).');
    scanText = uicontrol('Style','text','String','Scanning for Agents',...
        'Position',[300,300,100,50]);
    scanButton = uicontrol('Style','pushbutton','String',...
        'Start Scan','Position',[300,250,100,50],'Callback',...
        @scanButton_callback,'TooltipString',...
        'Start scanning mode to connect to remote agents before selection of Assignment/Fusion.');
    stopScanButton = uicontrol('Style','pushbutton','String',...
        'Stop Scan','Position',[300,150,100,50],'Callback',...
        @stopScanButton_callback,'TooltipString',...
        'Stop scanning mode when all agents have been connected.');
	startButton = uicontrol('Style','pushbutton','String','Start',...
        'Position',[100,100,100,50],'Callback',@startButton_callback,...
        'TooltipString','Initiate image labeling experiment.');
    align([assignmentText,assignmentMenu,fusionText,fusionMenu,...
        startButton],'Left','Distribute');
    
    % New way of inputing assignment parameters through the gui. 
    Assignment = []; AssignInfo = [];
    editBoxText = uicontrol('Visible','off','Style','text','String',' ','Position',...
        [30 25 350 25]);
    editBox = uicontrol('Visible','off','Style','edit','Position',...
        [355 30 50 25],'Callback',@AssignmentBox_callback);
    batchSize=0;
    policy = zeros(2,1);
    interval=0;
    threshold=0;
    
    gui.Name = 'Experiment';
    movegui(gui,'center')
    gui.Visible = 'on';
    
    function startButton_callback(~,~) 
    % STARTBUTTON_CALLBACK starts the experiment
        notify(experiment.control,'beginExperiment');
        infoText.String = 'Experiment Started.';
    end

    function scanButton_callback(~,~) 
    % SCANBUTTON_CALLBACK begins scanning for agents
        scanForAgents(experiment);    
        infoText.String = 'Scanning for new Agents...';
    end

    function stopScanButton_callback(~,~)
    % STOPSCANBUTTON_CALLBACK ends scanning for agents
        stopScanForAgents(experiment);
        infoText.String = 'Scan Stopped. Select Assignment Method.';
    end

    function assignmentMenu_callback(source,~) 
    % ASSIGNMENTMENU_CALLBACK uses the uicontrol in the gui to set the 
    % assignment property of the control
        str = source.String;
        val = source.Value;
        if ~isempty(str{val})
            switch str{val}
                case 'gap'
                    Assignment = str{val};
                    AssignInfo = 1;
                    editBoxText.String = 'Enter iteration interval length in seconds: ';
                    editBoxText.Visible = 'on';
                    editBox.Visible = 'on';
                case 'serial'
                    Assignment = str{val};
                    AssignInfo = 1;
                    editBoxText.String = 'Enter batch size to send to the CV: ';
                    editBoxText.Visible = 'on';
                    editBox.Visible = 'on';
                case 'serial_bci'
                    Assignment = str{val};
                    AssignInfo = 1;
                    editBoxText.String = 'Enter batch size to send to the CV: ';
                    editBoxText.Visible = 'on';
                    editBox.Visible = 'on';
                case 'all'
                    Assignment = str{val};
                    changeAssignment(experiment.control,str{val});
                otherwise
                    return
            end
        end
    end

    function AssignmentBox_callback(source,~)
    % ASSIGNMENTBOX_CALLBACK gets and sets the assignment properties from
    % the gui to be sent to the control (this replaces the command line
    % version from ealier. A bit more code involved but it makes for a 
    % cleaner user interface.)
        switch Assignment
            case 'gap'
                switch AssignInfo
                    case 1
                        interval = str2double(source.String);
                        editBoxText.String = 'Enter image confidence threshold:';
                        editBox.String='';
                        AssignInfo = AssignInfo+1;
                    case 2
                        threshold = str2double(source.String);
                        editBoxText.Visible='off';
                        editBox.Visible = 'off';
                        editBox.String='';
                        infoText.String = 'Select Fusion Method.';
                        changeAssignment(experiment.control,Assignment,interval,threshold);
                end
            case 'serial'
                switch AssignInfo
                    case 1
                        batchSize = str2double(source.String);
                        editBoxText.String = 'Enter release probability to human for class 1:';
                        editBox.String='';
                        AssignInfo = AssignInfo+1;
                    case 2
                        policy(1,1) = str2double(source.String);
                        editBoxText.String = 'Enter release probability to human for class 2:';
                        editBox.String='';
                        AssignInfo = AssignInfo+1;
                    case 3
                        policy(2,1) = str2double(source.String);
                        editBoxText.Visible='off';
                        editBox.Visible = 'off';
                        editBox.String='';
                        infoText.String = 'Select Fusion Method.';
                        changeAssignment(experiment.control,Assignment,batchSize,policy);
                end
            case 'serial_bci'
                switch AssignInfo
                    case 1
                        batchSize = str2double(source.String);
                        editBoxText.String = 'Enter release probability to human for class 1:';
                        editBox.String='';
                        AssignInfo = AssignInfo+1;
                    case 2
                        policy(1,1) = str2double(source.String);
                        editBoxText.String = 'Enter release probability to human for class 2:';
                        editBox.String='';
                        AssignInfo = AssignInfo+1;
                    case 3
                        batchSize = str2double(source.String);
                        editBoxText.String = 'Enter release probability to human for class 1:';
                        editBox.String='';
                        AssignInfo = AssignInfo+1;
                    case 4
                        policy(1,1) = str2double(source.String);
                        editBoxText.String = 'Enter release probability to human for class 2:';
                        editBox.String='';
                        AssignInfo = AssignInfo+1;
                    case 5
                        policy(2,1) = str2double(source.String);
                        editBoxText.Visible='off';
                        editBox.Visible = 'off';
                        editBox.String='';
                        infoText.String = 'Select Fusion Method.';
                        changeAssignment(experiment.control,Assignment,batchSize,policy);
                end
        end
    end

    function fusionMenu_callback(source,~) 
    % ASSIGNMENTMENU_CALLBACK sets the assignment property of the control
    % object
        str = source.String;
        val = source.Value;
        if ~isempty(str{val})
            experiment.control.fusion = str{val};
        end
        infoText.String = 'Experiment Ready. Select "Start".';
    end

end