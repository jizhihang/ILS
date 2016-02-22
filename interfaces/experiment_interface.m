function gui = experiment_interface(experiment)
% EXPERIMENT_INTERFACE

    gui = figure('Visible','off','Position',[300,300,300,450]);

    assignmentText = uicontrol('Style','text','String','Assignment',...
        'Position',[100,325,100,50]);
    assignmentMenu = uicontrol('Style','popupmenu','String',{'all',...
        'random','gap','serial'},'Position',[100,300,100,50],...
        'Callback',@assignmentMenu_callback);
	fusionText = uicontrol('Style','text','String','Fusion','Position',...
        [100,225,100,50]);
    fusionMenu = uicontrol('Style','popupmenu','String',...
        {'sum','mv','sml'},'Position',[100,200,100,50],'Callback',...
        @fusionMenu_callback);
	startButton = uicontrol('Style','pushbutton','String','Start',...
        'Position',[100,100,100,50],'Callback',@startButton_callback);
    align([assignmentText,assignmentMenu,fusionText,fusionMenu,...
        startButton],'Left','Distribute');
    
    assignmentText.Units = 'normalized';
    assignmentMenu.Units = 'normalized';
    fusionText.Units = 'normalized';
    fusionMenu.Units = 'normalized';
    startButton.Units = 'normalized';
    
    gui.Name = 'Experiment';
    movegui(gui,'center')
    gui.Visible = 'on';
    
    function startButton_callback(source,eventdata) 
    % STARTBUTTON_CALLBACK starts the experiment
        startExperiment(experiment)
    end

    function assignmentMenu_callback(source,eventdata) 
    % ASSIGNMENTMENU_CALLBACK sets the assignment property of the control
    % object
        str = source.String;
        val = source.Value;
        changeAssignment(experiment.control,str{val});
    end

    function fusionMenu_callback(source,eventdata) 
    % ASSIGNMENTMENU_CALLBACK sets the assignment property of the control
    % object
        str = source.String;
        val = source.Value;
        experiment.control.fusion = str{val};
    end

end

