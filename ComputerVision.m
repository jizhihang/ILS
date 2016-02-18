classdef ComputerVision < RemoteAgent
% COMPUTERVISION is a child of the LocalAgent superclass. It uses a
% computer vision algorithm to classify images.
    
    properties
        model
    end
    
    methods
        % -----------------------------------------------------------------
        % Class constructor:
        
        function A = ComputerVision(remotePort,imageDirectory,cvModel)
            if nargin < 1
                error('Too few parameters for class construction.');
            end
            A@RemoteAgent('cv',remotePort,imageDirectory);
            A.model = cvModel;
        end
        
        %------------------------------------------------------------------
        % Dependencies:
        
        function Y = classifyImages(obj,src,event)
        % CLASSIFYIMAGES is a callback function which is initiated by the
        % receipt of an image assignment from a local agent. It will
        % classify images or terminate the agent upon receipt of the
        % 'complete' command.
            X = fread(obj.socket);
            if strcmp(char(X)','complete')
                terminate(obj);
            else
                Y = zeros(length(X),1);
                images = getImages(X); % gets images from directory
                % classify images
                % extract deep features
                features = ExtractFeatures(images);
                % classify images
                Y = ClassifyFeatures(features);
                fwrite(obj.socket,Y(:));
                fprintf('Computer vision completed classification of %u images.\n',...
                    length(X))
            end
        end
        
        function features = ExtractFeatures(Images,layer)
        % EXTRACTFEATURES is CV module that runs images through a
        % pre-trained deep convolutional neural network (DCNN), and
        % extracts the features from a specified layer (default layer is
        % the top layer). 
        % Input: cell array of images
        % Output: 2d matrix of features (images x features)
        if(nargin==1)
            layer = 20;
        end
        net = load('imagenet-caffe-alex');                          % load DNN
        
        for i=1:length(Images)
            Image{i} = single(Image{i});                                      % convert to single
            Image{i} = imresize(Image{i}, net.normalization.imageSize(1:2));  % re-size
            Image{i} = Image{i} - net.normalization.averageImage;             % subtract mean
            res{i} = vl_simplenn(net, Image{i});                              % extract features
            tmp = squeeze(res(layer).x);
            features(i,:) = tmp(:);
        end
        end
        
        function [pred_label, score, accuracy] = ClassifyFeatures(Features, Model, options, Labels)
        % CLASSIFYFEATURES is CV module that uses a shalow learner (SVM) to
        % classify extracted image features. An already trained SVM model
        % must be provided for classifcation. 
        % Input: Matrix of Image features, SVM model, SVM options
        % (optional), Labels (optional)
        % Output: Predictions, score, accuracy (if labels were provided)
            if(nargin<2)
                Model = load('SVMmodel');
            end
            if(nargin<3)
                options = '-q';
            end
            if(nargin<4)
                Labels = ones(size(Features,1));
            end
            % predict image labels
            [pred_label, accuracy, score] = svmpredict(Labels,Features,Model,options); 
        end
        %------------------------------------------------------------------
        
    end
    
end
