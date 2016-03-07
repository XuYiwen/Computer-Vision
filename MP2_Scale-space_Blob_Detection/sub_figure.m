function [img_space,scl_space] = sub_figure(img,sigma,k,n)
    [h,w] = size(img);
    img_space = zeros(h,w,n);
    scl_space = zeros(n,1);scl_space(1) = 1;
    
    t_start = tic;
    lap = fspecial('log',6*sigma,sigma);
    nor_lap = lap.*(sigma^2);
    sig = 1;
    for i = 1:n
%         ims = imresize(img,1/sig);
        ims = imresize(img,[ceil(h/sig),ceil(w/sig)]);
        imf = imfilter(ims,nor_lap,'symmetric');
        imf = imf.^2;
        imu = imresize(imf,[h,w],'bicubic');
        sig = k^i;

        img_space(:,:,i) = imu;
        scl_space(i+1) = sig;
    end
    t = toc(t_start);
    fprintf('Running Time - Subsampled Image: %6.6f s\n',t);

    scl_space = scl_space(1:n,1).*sigma.*sqrt(2);
end