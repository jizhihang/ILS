classdef ComputerVision < RemoteAgent
% COMPUTERVISION is a child of the LocalAgent superclass. It uses a
% computer vision algorithm to classify images.
    
    properties
        SVMmodel
        DNNnet
        SVMscale
    end
    
    methods
        % -----------------------------------------------------------------
        % Class constructor:
        
        function A = ComputerVision(imageDirectory)
            if nargin < 1
                error('Too few parameters for class construction.');
            end
            A@RemoteAgent('cv',remotePort,imageDirectory);
            
            % Load and set up DNN Feature Extractor
%             [A.DNNnet, A.SVMmodel] = Initialize();
            net=load('imagenet-vgg-verydeep-16.mat');
            dnn = net;
%             for i=1:length(net.layers)
%                 try
%                     dnn.layers{i}.weights{1}=gpuArray(net.layers{i}.weights{1});
%                     dnn.layers{i}.weights{2}=gpuArray(net.layers{i}.weights{2});
%                 catch
%                 end
%             end
            A.DNNnet = dnn;
            tmp = load('SVMmodel');
            A.SVMmodel = tmp.svmModel;
            A.SVMscale = load('SVMscale');
        end
        
        %------------------------------------------------------------------
        % System-Level:
        
        function Y = classifyImages(obj,src,event)
        % CLASSIFYIMAGES is a callback function which is initiated by the
        % receipt of an image assignment from a local agent. It will
        % classify images or terminate the agent upon receipt of the
        % 'complete' command.
            X = fread(obj.socket,obj.socket.bytesAvailable,'uint16');
            if strcmp(char(X)','complete')
                terminate(obj);
            elseif strcmp(char(X)','test')
                return
            else
                images = getImages(obj,X); % gets images from directory
                % classify images
                % extract deep features
                features = ExtractFeatures(obj,images,obj.DNNnet);
                % classify images
                Y = ClassifyFeatures(obj,features,obj.SVMmodel,obj.SVMscale);
                fwrite(obj.socket,Y(:),'uint8');
                fprintf('Computer vision completed classification of %u images.\n',...
                    length(X))
            end
        end
        
        %------------------------------------------------------------------
        % Dependencies:
        
        function features = ExtractFeatures(obj,Images,net,layer)
        % EXTRACTFEATURES is CV module that runs images through a
        % pre-trained deep convolutional neural network (DCNN), and
        % extracts the features from a specified layer (default layer is
        % the top layer). 
        % Input: cell array of images
        % Output: 2d matrix of features (images x features)
            if(nargin<4)
                layer = 37;
            end

            for i=1:length(Images)
                Im = single(Images{i}); % convert to single
                
                sizeTuple = py.tuple({net.normalization.imageSize(1:2)})
                
                Im = py.cv2.resize(Im,sizeTuple
                Im = imresize(Im, net.normalization.imageSize(1:2)); % re-size
                Im = Im - net.normalization.averageImage; % subtract mean
%                 imGpu = gpuArray(Im);
                imGpu = Im;
                res = vl_simplenn(net, imGpu); % extract features
                tmp = double(gather(squeeze(res(layer).x)));
                features(i,:) = tmp(:);
            end
        end
        
        function [pred_label, score, accuracy] = ClassifyFeatures(obj,...
                Features, Model,scale, options, Labels)
        % CLASSIFYFEATURES is CV module that uses a shalow learner (SVM) to
        % classify extracted image features. An already trained SVM model
        % must be provided for classifcation. 
        % Input: Matrix of Image features, SVM model, SVM options
        % (optional), Labels (optional)
        % Output: Predictions, score, accuracy (if labels were provided)
            if(nargin<5)
                options = '-q';
            end
            if(nargin<6)
                Labels = ones(1,size(Features,1));
            end
            % predict image labels
            Features(Features<0)=0;
            Features = (Features - scale.scale_min) /...
                (scale.scale_max - scale.scale_min);
            [pred_label, accuracy, score] = svmpredict(Labels',...
                Features,Model,options); 
        end
        
        %------------------------------------------------------------------
    end
    
    methods (Static)
        %------------------------------------------------------------------
        % Dependencies:
        
        function [dnn, model] = Initialize() 
        % INITIALIZE loads the DNN into GPU memory to be usable for fast
        % feature extraction of images, and loads a pre-trained SVM model.
        % In future versions, we will have a feature to train/re-train an
        % SVM model on the fly.
            net=load('imagenet-vgg-verydeep-16.mat');
            dnn = net;
            for i=1:length(net.layers)
                try
                    dnn.layers{i}.weights{1}=gpuArray(net.layers{i}.weights{1});
                    dnn.layers{i}.weights{2}=gpuArray(net.layers{i}.weights{2});
                catch
                end
            end
            model = load('SVMmodel');
        end
        
        %------------------------------------------------------------------
    end
    
end
