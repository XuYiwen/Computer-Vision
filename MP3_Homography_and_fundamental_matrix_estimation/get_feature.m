function [keypt,des] = get_feature(img,method,display,picname)
    
    % detect keypoints
    thresh = 0.02;
    sigma = 1;
    if strcmp(method,'blob')
        % blob detection
        [~,ly,lx,lr] = blob(img,sigma,50,12,1,thresh);
    else
        % harris corner detection
        [~,ly,lx] = harris(img,sigma,thresh,1);
        lr = ones(size(lx)).*5;
    end
    keypt = [lx,ly,lr];
    
    % delete boundary points
    [h,w] = size(img);
    in_boundary = (ly-lr>0) & (ly+lr-h<0) & (lx-lr>0) & (lx+lr-w<0);
    id = find(~in_boundary);
    keypt(id,:) = []; 
    
    % compute descriptor
    des = find_sift(img, keypt, 2); 
    
    % display features
    if display
        figure(),show_features(img,keypt);
        fig = gcf;
        fig.PaperPositionMode = 'auto';
        capture = ['out/', sprintf('%s-%s-features',picname,method)];
        print(capture,'-dpng','-r0');
    end
end

function show_features(I,keypts,color,ln_wid)
% Input:
%     I - image to display feature on;
%     keypts - each feature in one row, with col order of [left-right(x),up-down(y),rad]
%     color - (optional) circle color;
%     ln_wid - (optional) line-width of circles;

    if nargin < 3
        color = 'r';
    end

    if nargin < 4
       ln_wid = 1;
    end
    
    cx = keypts(:,1);
    cy = keypts(:,2);
    rad = keypts(:,3);
    
    imshow(I); hold on;
        theta = 0:0.1:(2*pi+0.1);
        cx1 = cx(:,ones(size(theta)));
        cy1 = cy(:,ones(size(theta)));
        rad1 = rad(:,ones(size(theta)));
        theta = theta(ones(size(cx1,1),1),:);
        X = cx1+cos(theta).*rad1;
        Y = cy1+sin(theta).*rad1;
        line(X', Y', 'Color', color, 'LineWidth', ln_wid);
        title(sprintf('%d circles', size(cx,1)));

end