function [cim,x,y,r] = blob(img,sigma,maxR,iter,radius,thresh)
    k = nthroot(maxR/sqrt(2)/sigma,iter);
    [h,w] = size(img);
    
    %% Build Laplacian Pyramid
    img_space = zeros(h,w,iter);
    scl_space = zeros(iter,1);scl_space(1) = 1;
    
    lap = fspecial('log',6*sigma,sigma);
    nor_lap = lap.*(sigma^2);
    sig = 1;
    for i = 1:iter
        ims = imresize(img,[ceil(h/sig),ceil(w/sig)]);
        imf = imfilter(ims,nor_lap,'symmetric');
        imf = imf.^2;
        imu = imresize(imf,[h,w],'bicubic');
        sig = k^i;

        img_space(:,:,i) = imu;
        scl_space(i+1) = sig;
    end
    scl_space = scl_space(1:iter,1).*sigma.*sqrt(2);

    if false
        figure(3);
        set(gcf,'position',[1 500 1600 700]);
        num = size(img_space,3);
        row_num = 3;
        per_row = ceil(num/row_num);
        for i = 1:num
            subplot(row_num,per_row,i),imagesc(img_space(:,:,i)),axis off, colorbar;
        end
        
        fig = gcf;
        fig.PaperPositionMode = 'auto';
        capture = ['out/', sprintf('%s-pyramid',outname)];
        print(capture,'-dpng','-r0');
    end
    
    %% Nonmaximum Suppression
    % Slidewise Nonmaximum Suppression
    maxi_space = img_space;
    sz = 2*radius+1;
    n = size(img_space,3);
    for i = 1:n
        maxi_space(:,:,i) = ordfilt2(img_space(:,:,i),sz^2,ones(sz));
    end

    % Third Dimension Nonmaximum Suppression
    x =[]; y = []; r = [];
    cim = zeros(h,w);
    for i = 1:n
        cur = maxi_space(:,:,i);
        cur_up = ones(size(cur)); cur_down = ones(size(cur));
        if (i>1) up = maxi_space(:,:,i-1); cur_up = (cur-up)>0; end
        if (i<n) down = maxi_space(:,:,i+1); cur_down = (cur-down)>0; end
        at_max_level = (cur_up) & (cur_down);

        im = img_space(:,:,i); 
        at_max_center = (im == cur) & (im > thresh);

        imcur = at_max_level .* at_max_center;

        [cx,cy] = find(imcur); 
        cim = cim | imcur;
        cr = ones(size(cx)).*scl_space(i);
        x = [x;cx]; y = [y;cy]; r = [r;cr];
    end
    
    if false
        figure(4),show_all_circles(img, y, x, r);
        fig = gcf;
        fig.PaperPositionMode = 'auto';
        capture = ['out/', sprintf('%s-blob',outname)];
        print(capture,'-dpng','-r0');
    end
end
