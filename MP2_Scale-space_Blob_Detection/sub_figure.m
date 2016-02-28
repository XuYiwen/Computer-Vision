function [img_space,scl_space] = sub_figure(img,sigma,k,n,display)
    [h,w] = size(img);
    img_space = zeros(h,w,n);
    scl_space = zeros(n,1);scl_space(1) = 1;
    
    t_start = tic;
    lap = fspecial('log',6*sigma,sigma);
    nor_lap = lap.*(sigma^2);
    sig = 1;
    for i = 1:n
        ims = imresize(img,1/sig,'Antialiasing',true);
        imf = imfilter(ims,nor_lap,'symmetric');
        imf = imf.^2;
        imu = imresize(imf,[h,w],'bicubic');
        sig = k^i;

        img_space(:,:,i) = imu;
        scl_space(i+1) = sig;
    end
    t = toc(t_start);
    fprintf('Running Time - Subsampled Image: %6.6f s\n',t);

    
    if display
        figure(3),title('Filtered image at diff levels');
        set(gcf,'position',[1 500 1800 500]);
        per_row = ceil(n/2);
        for i = 1:n
            subplot(2,per_row,i),imagesc(img_space(:,:,i));
        end
    end
    
    scl_space = scl_space(1:n,1).*sigma.*sqrt(2);
end