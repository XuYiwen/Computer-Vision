function [img_space,scl_space] = DoG(img,sigma,maxR,s,display)
    [h,w] = size(img); 
    
    % Calculate numbers of octave
    num_oct = 0;
    ini_sig = sigma;
    while (maxR/sqrt(2) > ini_sig*(2^num_oct)) 
        num_oct = num_oct+1;   
    end
        
    img_space = zeros(h,w,num_oct*s);
    scl_space = zeros(num_oct*s,1);scl_space(1) = ini_sig;
    
    t_start = tic;
    
    % intialization
    subh = h; subw = w;
    gau_sig = fspecial('gaussian',ini_sig*6,ini_sig);
    ini_img = imfilter(img,gau_sig,'symmetric');   
    k = nthroot(2,s)
    gau_k = fspecial('gaussian',ceil(k*6),k);  
    
    for i = 1:num_oct
        % initial gaussian image stack
        gimg_stack = zeros(subh, subw, s+1);
        gimg_stack(:,:,1) = ini_img;
        
        for j = 1:s
            % compute upper layer of guassian-ed image
            last = gimg_stack(:,:,j);
            next = imfilter(last,gau_k,'symmetric');
            gimg_stack(:,:,j+1) = next;
            
            % substract and put into DoG stack
            DoG = next - last;
            DoG = imresize(DoG,[h,w],'bicubic');
            img_space(:,:,i) = DoG;
            scl_space(:,:,i) = ini_sig * k^(j-1);
        end
        
        % update new ini_sig and ini_img
        subh = ceil(h/(2^i));
        subw = ceil(w/(2^i));
        ini_img = imresize(gimg_stack(:,:,end),[subh,subw]);
        ini_img = imfilter(ini_img,gau_sig,'symmetric');  
    end
    t = toc(t_start);
    fprintf('Running Time - DoG: %6.6f s\n',t);

    if display
        n = num_oct*s;
        figure(2),title('Filtered image at diff levels');
        set(gcf,'position',[1 1 1800 500]);
        
        per_row = ceil(n/2);
        for i = 1:n
            subplot(2,per_row,i),imagesc(img_space(:,:,i));
        end
    end
    
    scl_space = scl_space(1:n,1).*sqrt(2);
end