function [img_space,scl_space] = up_kernel(img,sigma,k,n,display)
    [h,w,~] = size(img); 
    img_space = zeros(h,w,n);
    scl_space = zeros(n,1);scl_space(1) = sigma;
    
    t_start = tic;
    sig = sigma;
    for i = 1:n
        lap = fspecial('log',6*sig,sig);
        nor_lap = lap.*(sig^2);
        imf = imfilter(img,nor_lap,'symmetric');
        imf = imf.^2;
        sig = round(sigma*(k^i));
        
        img_space(:,:,i) = imf;
        scl_space(i+1) = sig; % actually you dont need this 
    end
    t = toc(t_start);
    fprintf('Running Time - Upsampled Kernel: %6.6f s\n',t);

    if display
        figure(2);
        set(gcf,'position',[1 1 1800 500]);
        
        per_row = ceil(n/2);
        for i = 1:n
            subplot(2,per_row,i),imagesc(img_space(:,:,i)),axis off,colorbar;
        end
    end
    
    scl_space = scl_space(1:n,1).*sqrt(2);
end