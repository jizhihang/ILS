%% Add paths
addpath(genpath('/data2/software/matconvnet-1.0-beta18'))
addpath(genpath('/data2/software/stable/LibSVM'))
addpath(genpath('/data2/data/101_ObjectCategories'))

%% load the pre-trained CNN
net = load('imagenet-matconvnet-vgg-f.mat');
net = vl_simplenn_tidy(net);
for i=1:length(net.layers)
    try
        net.layers{1,i}.weights{1}=gpuArray(net.layers{1,i}.weights{1});
        net.layers{1,i}.weights{2}=gpuArray(net.layers{1,i}.weights{2});
    catch
    end
end
layer = 19;

%% Load the image and extract features
imdir = dir('/data2/data/101_ObjectCategories/brain');
imdir = imdir(3:end);
features = zeros(length(imdir),1000);
for i=1:length(imdir)
    im = single(imread(imdir(i).name)); % convert to single
    im = imresize(im,net.meta.normalization.imageSize(1:2)); % re-size
    im(:,:,1) = im(:,:,1) - net.meta.normalization.averageImage(1); % subtract mean
    try
        im(:,:,2) = im(:,:,2) - net.meta.normalization.averageImage(2);
        im(:,:,3) = im(:,:,3) - net.meta.normalization.averageImage(3);
    catch
        im(:,:,2:3) = 0;
    end
    im_ = gpuArray(im);
    res = vl_simplenn(net,im_); % extract features
    tmp = double(gather(squeeze(res(layer).x)));
    features(i,:) = tmp(:)';
end

%% Train SVM model

labels = ones(length(imdir),1);
svm = svmtrain(labels,features,'-s 2');

%% Classify features with libSVM

[pred_label,accuracy,score] = svmpredict(labels,features,svm); 
