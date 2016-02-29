function [img_space,scl_space] = DoG(img,ini_sig,maxR,perlayer,display)
    [h,w,~] = size(img); 
    
    % Calculate numbers of octave
    num_oct = 0;
    while (maxR/sqrt(2) > ini_sig*(2^num_oct)) 
        num_oct = num_oct+1;   
    end
        
    img_space = zeros(h,w,n*perlayer);
    scl_space = zeros(n*perlayer,1);scl_space(1) = ini_sig;
    
    t_start = tic;
    for i = 1:num_oct
        sc = 2^(i-1);
        this_oct = zeros(h,w)
        for j = 1:perlayer
            
        end
    end
    
    sig = ini_sig;
    for i = 1:n
        lap = fspecial('log',6*sig,sig);
        nor_lap = lap.*(sig^2);
        imf = imfilter(img,nor_lap,'symmetric');
        imf = imf.^2;
        sig = round(ini_sig*(k^i));
        
        img_space(:,:,i) = imf;
        scl_space(i+1) = sig; % actually you dont need this 
    end
    t = toc(t_start);
    fprintf('Running Time - Upsampled Kernel: %6.6f s\n',t);

    if display
        figure(2),title('Filtered image at diff levels');
        set(gcf,'position',[1 1 1800 500]);
        
        per_row = ceil(n/2);
        for i = 1:n
            subplot(2,per_row,i),imagesc(img_space(:,:,i));
        end
    end
    
    scl_space = scl_space(1:n,1).*sqrt(2);
end