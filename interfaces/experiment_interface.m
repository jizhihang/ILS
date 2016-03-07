function gui = experiment_interface(experiment)
% EXPERIMENT_INTERFACE

    gui = figure('Visible','off','Position',[300,300,300,450]);

    assignmentText = uicontrol('Style','text','String','Assignment',...
        'Position',[100,325,100,50]);
    assignmentMenu = uicontrol('Style','popupmenu','String',{'all',...
        'gap','serial','serialPrototype'},'Position',[100,300,100,50],...
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
%         startExperiment(experiment)
        fclose(experiment.socket);
        delete(experiment.socket);
        addResultsListener(experiment.control.assignment);
        notify(experiment.control,'beginExperiment');
    end

    function assignmentMenu_callback(source,eventdata) 
    % ASSIGNMENTMENU_CALLBACK sets the assignment property of the control
    % object
        str = source.String;
        val = source.Value;
        switch str{val}
            case 'serial'
                batchSize = input('Enter batch size to send to the CV: ');
    %             numClasses = input('Enter the number of unique classes in database: ');
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

    function fusionMenu_callback(source,eventdata) 
    % ASSIGNMENTMENU_CALLBACK sets the assignment property of the control
    % object
        str = source.String;
        val = source.Value;
        experiment.control.fusion = str{val};
    end

end

