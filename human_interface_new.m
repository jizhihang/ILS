function gui = human_interface_new(human,images)
% EXPERIMENT_INTERFACE

    gui = figure('Visible','off','Position',[300,300,450,550]);
    image = axes('Units','pixels','Position',[50,150,350,350]);
    targetButton = uicontrol('Style','pushbutton','String','Target',...
        'Position',[100,50,100,50],'Callback',@targetButton_callback);
    nonTargetButton = uicontrol('Style','pushbutton','String','Non-target',...
        'Position',[250,50,100,50],'Callback',@nonTargetButton_callback);
    
    image.Units = 'normalized';
    targetButton.Units = 'normalized';
    nonTargetButton.Units = 'normalized';
    
    n = length(images);
    k = 1;
    imshow(images{k});
    
    gui.Name = 'Human';
    movegui(gui,'center')
    gui.Visible = 'on';
    
    function targetButton_callback(source,eventdata) 
    % TARGETBUTTON_CALLBACK classifies the image as a target
        if k <= n
            human.response(k) = 1;
            if k < n
                k = k + 1;
                imshow(images{k});
                return;
            end
            notify(human,'iterationComplete');
        end
    end

    function nonTargetButton_callback(source,eventdata) 
    % NONTARGETBUTTON_CALLBACK classifies the image as a target
        if k <= n
            human.response(k) = 0;
            k = k + 1;
            imshow(images{k});
        else
            notify(human,'iterationComplete');
        end
    end

end

