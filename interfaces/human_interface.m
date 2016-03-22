function gui = human_interface(human,images)
% HUMAN_INTERFACE provides the binary classification interface for the
% human self-paced labeler. It loads the assigned images and writes the
% classification responses to a field in the human object.
global k n  gImages gHuman;
    gui = figure('Visible','off','Position',[300,300,750,750],'DockControls','off'...
        ,'MenuBar','none','NumberTitle','off');
    image = axes('Units','pixels','Position',[50,150,650,550]);
    targetButton = uicontrol('Style','pushbutton','String','Target','FontSize',14,...
        'Position',[225,50,125,65],'Callback',@targetButton_callback);
    nonTargetButton = uicontrol('Style','pushbutton','String','Non-target','FontSize',14,...
        'Position',[400,50,125,65],'Callback',@nonTargetButton_callback);
    
    image.Units = 'normalized';
    targetButton.Units = 'normalized';
    nonTargetButton.Units = 'normalized';
    
    n = length(images);
    k = 1;
    imshow(images{k});
    
    gui.Name = 'Human Agent';
    movegui(gui,'center')
    gui.Visible = 'on';
    
gImages = images;
gHuman = human;

end

function targetButton_callback(~,~)
% TARGETBUTTON_CALLBACK - callback function for the human interface
% selection of the target button. this function records the human
% classification, updates the image and notifies the listener when all
% images have been classified.
global gImages k n gHuman
% TARGETBUTTON_CALLBACK classifies the image as a target
if k <= n
    gHuman.response(k) = 1;
    if k < n
        k = k + 1;
        imshow(gImages{k});
        return;
    end
    notify(gHuman,'iterationComplete');
end
end

function nonTargetButton_callback(~,~)
% NONTARGETBUTTON_CALLBACK - callback function for the human interface
% selection of the non-target button. this function records the human
% classification, updates the image and notifies the listener when all
% images have been classified.
% NONTARGETBUTTON_CALLBACK classifies the image as a target
global gImages k n gHuman
if k <= n
    gHuman.response(k) = -1;
    if k < n
        k = k + 1;
        imshow(gImages{k});
        return;
    end
    notify(gHuman,'iterationComplete');
end
end
