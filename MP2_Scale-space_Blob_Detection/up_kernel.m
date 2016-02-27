function [img_space,scl_space] = up_kernel(img,sigma,k,n,display)
    [h,w,~] = size(img); 
    img_space = zeros(h,w,n);
    scl_space = zeros(n,1);scl_space(1) = sigma;
    
    t_start = tic;
    for i = 1:n
        lap = fspecial('log',7*sigma,sigma);
        nor_lap = lap.*(sigma^2);
        imf = imfilter(img,nor_lap,'symmetric');
        imf = imf.^2;
        sigma = round(sigma*k);
        
        img_space(:,:,i) = imf;
        scl_space(i+1) = sigma; % actually you dont need this 
    end
    t = toc(t_start);
    sprintf('Running Time - Upsampled Kernel: %6.6f s',t)

    if display
        figure(2),title('Filtered image at diff levels');
        per_row = ceil(n/2);
        for i = 1:n
            subplot(2,per_row,i),imagesc(img_space(:,:,i));
        end
    end
    
    scl_space = scl_space(1:n,1).*sqrt(2);
end