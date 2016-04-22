%% Add paths
addpath(genpath('/data2/software/matconvnet-1.0-beta18'))
addpath(genpath('/data2/software/stable/LibSVM'))
addpath(genpath('/data2/data/101_ObjectCategories'))

impath = '/data2/data/101_ObjectCategories/brain';
net = 'imagenet-matconvnet-vgg-f.mat';

%% Load the images

imdir = dir(impath);
imdir = imdir(3:end);
images = cell(length(imdir),1);
for i=1:length(imdir)
    images{i} = imread(imdir(i).name);
end
labels = ones(length(images),1);
shuffle = randperm(length(images));
train_set = shuffle(1:50);
test_set = shuffle((end-50),end);

%% Train SVM model

model = train_cv(images(train_set),labels,net,true);

%% Test SVM model

[pred_labels,scores] = test_cv(images(test_set),model,net,true);
