function [labels,scores] = test_cv(images,model,net,gpu)

    net = vl_simplenn_tidy(load(net));
    out = max(size(net.layers));
    features = zeros(length(images),length(net.layers{out-1}.weights{2}));
    
    if gpu
        for i=1:length(net.layers)
            try
                net.layers{1,i}.weights{1}=gpuArray(net.layers{1,i}.weights{1});
                net.layers{1,i}.weights{2}=gpuArray(net.layers{1,i}.weights{2});
            catch
            end
        end
    end
    
    for i=1:length(images)
        im = single(images{i});
        im = imresize(im,net.meta.normalization.imageSize(1:2));
        im(:,:,1) = im(:,:,1) - net.meta.normalization.averageImage(1);
        try
            im(:,:,2) = im(:,:,2) - net.meta.normalization.averageImage(2);
            im(:,:,3) = im(:,:,3) - net.meta.normalization.averageImage(3);
        catch
            im(:,:,2:3) = 0;
        end
        if gpu
            im = gpuArray(im);
            res = vl_simplenn(net,im);
            tmp = double(gather(squeeze(res(out).x)));
        else
            res = vl_simplenn(net,im);
            tmp = double(squeeze(res(out).x));
        end
        features(i,:) = tmp(:)';
    end
    
    [labels,~,scores] = svmpredict(ones(size(features,1),1),features,model); 

end
