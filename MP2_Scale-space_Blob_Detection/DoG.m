function [dogpyr,sclpyr] = DoG(img,ini_sig,maxR,nOctLayers)
    [h,w] = size(img); 
    
    % Calculate numbers of octave
    num_oct = 0;
    while (maxR/sqrt(2) > ini_sig*(2^num_oct)) 
        num_oct = num_oct+1;   
    end
    k = nthroot(2,nOctLayers);
    
    t_start = tic;
    % Precompute guassian filter in octave
    gau_sig = fspecial('gaussian',ceil(ini_sig*6),ini_sig);
    gau_k = fspecial('gaussian',ceil(k*6),k);
    
    dogpyr = zeros(h,w,num_oct*(nOctLayers+2));
    sclpyr = zeros(num_oct*(nOctLayers+2),1);
    subh = h; subw = w;
    gau_octave = zeros(subh,subw,nOctLayers+3);
    gau_octave(:,:,1) = imfilter(img,gau_sig,'symmetric');
    for o = 1:num_oct
        for l = 2:nOctLayers+3
            % get next Gaussian level
            sigma = ini_sig*k^(l-1)*2^(o-1);
            gau_octave(:,:,l) = imfilter(gau_octave(:,:,l-1),gau_k,'symmetric');
            diff = gau_octave(:,:,l)- gau_octave(:,:,l-1);
            diff = diff.^2;
            dogpyr(:,:,(o-1)*(nOctLayers+2)+l-1) = imresize(diff,[h,w],'bicubic');
            sclpyr((o-1)*num_oct+l-1) = sigma/k;
        end
        top = gau_octave(:,:,nOctLayers+2);
        subh = ceil(subh/2);
        subw = ceil(subw/2);
        gau_octave = zeros(subh,subw,nOctLayers+3);
        gau_octave(:,:,1) = imresize(top,[subh,subw]);
    end
        t = toc(t_start);
    fprintf('Running Time - DoG Kernel: %6.6f s\n',t);
    
    sclpyr = sclpyr.*sqrt(2);
