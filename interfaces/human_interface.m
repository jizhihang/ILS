function gui = human_interface(human,images,flag)
% HUMAN_INTERFACE provides the binary classification interface for the
% human self-paced labeler. It loads the assigned images and writes the
% classification responses to a field in the human object.
    global k n assignmentCounter progressCounter gImages gHuman;
    if flag
        gui = figure('Visible','off','Position',[300,300,750,750],...
            'DockControls','off','MenuBar','none','NumberTitle','off');
        image = axes('Units','pixels','Position',[50,150,650,550]);
        targetButton = uicontrol('Style','pushbutton','String','Target',...
            'FontSize',14,'Position',[225,50,125,65],'Callback',...
            @targetButton_callback);
        nonTargetButton = uicontrol('Style','pushbutton','String',...
            'Non-target','FontSize',14,'Position',[400,50,125,65],...
            'Callback',@nonTargetButton_callback);

        image.Units = 'normalized';
        targetButton.Units = 'normalized';
        nonTargetButton.Units = 'normalized';

        assignmentCounter = 1;
        progressCounter = 1;
        n(assignmentCounter) = length(images);
        k = 1;
        imshow(images{k});

        gui.Name = 'Human Agent';
        movegui(gui,'center')
        gui.Visible = 'on';
        gHuman = human;
        gImages = images;
    else
       gImages = [gImages;images];
       n(assignmentCounter+1) = n(assignmentCounter) + length(images);
       assignmentCounter = assignmentCounter + 1;
       if(strcmp(gHuman.gui.Visible,'off')) 
           k=k+1;
           imshow(gImages{k});
       end
       gHuman = human;
       gHuman.gui.Visible = 'on';
    end
end

function targetButton_callback(~,~)
% TARGETBUTTON_CALLBACK - callback function for the human interface
% selection of the target button. this function records the human
% classification, updates the image and notifies the listener when all
% images have been classified.
    global gImages k n assignmentCounter progressCounter gHuman
    % TARGETBUTTON_CALLBACK classifies the image as a target
    if k <= n(progressCounter)
        if progressCounter > 1
            gHuman.response(k-n(progressCounter-1)) = 1;
        else
            gHuman.response(k) = 1;
        end
        if k < n(progressCounter)
            k = k + 1;
            imshow(gImages{k});
            return;
        end
        notify(gHuman,'iterationComplete');
        if assignmentCounter == progressCounter
            gHuman.gui.Visible = 'off';
        else
            k = k + 1;
            imshow(gImages{k});
        end
        progressCounter = progressCounter + 1;
    end
end

function nonTargetButton_callback(~,~)
% NONTARGETBUTTON_CALLBACK - callback function for the human interface
% selection of the non-target button. this function records the human
% classification, updates the image and notifies the listener when all
% images have been classified.
% NONTARGETBUTTON_CALLBACK classifies the image as a target
    global gImages k n assignmentCounter progressCounter gHuman
    % TARGETBUTTON_CALLBACK classifies the image as a target
    if k <= n(progressCounter)
        if progressCounter > 1
            gHuman.response(k-n(progressCounter-1)) = -1;
        else
            gHuman.response(k) = -1;
        end
        if k < n(progressCounter)
            k = k + 1;
            imshow(gImages{k});
            return;
        end
        notify(gHuman,'iterationComplete');
        if assignmentCounter == progressCounter
            gHuman.gui.Visible = 'off';
        else
            k = k + 1;
            imshow(gImages{k});
        end
        progressCounter = progressCounter + 1;
    end
end
