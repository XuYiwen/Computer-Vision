function Hrs = homography_estimate(imR,imS,display)
% Estimate the homography transformation from reference(img_R) to source(img_S)
%
% Input:
%      img_R - reference image
%      img_S - source image
%      img_R = Hrs * img_S
% Output:
%      Hrs - image level estimation of homography transformation matrix

    % Dimension correction 
    if ndims(imR) == 3
        img_R = im2double(rgb2gray(imR));
        img_S = im2double(rgb2gray(imS));
    else
        img_R = im2double(imR);
        img_S = im2double(imS);
    end

    % Extract features from both images
    method = 'blob';
    disp('>>>> Extract Features');
    [keypt_R,des_R] = get_feature(img_R,method,display,'refer');
    [keypt_S,des_S] = get_feature(img_S,method,display,'source');

    % Get matching pairs for image
    num_matches = 400;
    dis = dist2(des_R,des_S);
    top = sort(dis(:)); 
    th = top(min(num_matches,numel(dis)));
    [sR,sS] = find(dis<=th);
    matches = [sR,sS]';

    % pair matches to homogenous coordinates
    pos_R = keypt_R(matches(1,:),1:2)' ; pos_R(3,:) = 1 ;
    pos_S = keypt_S(matches(2,:),1:2)' ; pos_S(3,:) = 1 ;
    if display 
        show_matches(img_R,pos_R,img_S,pos_S,'pre');
    end

    % Automatic homography estimation with RANSAC
    disp('>>>> Perform RANSAC');
    iter = 5000;
    best_fit = 0;
    for t = 1: iter
        % estimate homograpyh using rand 4 pairs
        subset = randsample(size(matches,2),4);
        pts_R = pos_R(:, subset);
        pts_S = pos_S(:, subset);
        Htemp = homography(pts_R, pts_S); 
        if isempty(Htemp)
            continue;
        end

        % score homography
        [dist, inlier]= score_homography(Htemp,pos_R,pos_S,5);
        num_inlier = sum(inlier);

        % update best fit and compute average residual;
        if num_inlier > best_fit
            best_fit = num_inlier;
            Hrs = Htemp;

            idx = find(inlier);
            in_pos_R = pos_R(:,idx);
            in_pos_S = pos_S(:,idx);
            aver_res = sum(dist(idx))/num_inlier;
        end
    end
    % display
    fprintf('Num of Inliers - %d \n',best_fit);
    fprintf('Average residual - %.2f \n',aver_res);
    if display
        show_matches(img_R,in_pos_R,img_S,in_pos_S,'post');
        check_homography(Hrs,imR,imS);
    end
end 

function show_matches(img_R,pos_R,img_S,pos_S,picname)
    [h,w] = size(img_R);
    two_img = cat(2,img_R,img_S);
    pos_S(1,:) = pos_S(1,:)+ w;
    
    figure(),imshow(two_img),hold on;
    plot(pos_R(1,:),pos_R(2,:),'rx');
    plot(pos_S(1,:),pos_S(2,:),'mx');
    for i = 1: size(pos_R,2)
        x = [pos_R(1,i),pos_S(1,i)];
        y = [pos_R(2,i),pos_S(2,i)];
        plot(x,y,'g-');
    end
    hold off;
    title('feature matches');
        fig = gcf;
        fig.PaperPositionMode = 'auto';
        capture = ['out/', sprintf('%s-matches',picname)];
        print(capture,'-dpng','-r0');
end

function [dist, inlier]= score_homography(H,pos_R,pos_S,th)
    pos_R_ = H * pos_S ; % project points from first image to second using H
    du = pos_R_(1,:)./pos_R_(3,:) - pos_R(1,:)./pos_R(3,:) ;
    dv = pos_R_(2,:)./pos_R_(3,:) - pos_R(2,:)./pos_R(3,:) ;
    dist = sqrt(du.*du + dv.*dv);
    inlier = dist < th;  % distance threshold
end

function check_homography(H,R,S)
    % set 4 corners
    [h,w,~] = size(R);
    hh = 0.6*h;
    ww = 0.2*w;
    d = 90;
    pos_S = [ww,hh,1;   (ww+d),hh,1;   (ww+d),(hh+d),1;   ww,(hh+d),1]';
    
    % transform
    pos_R = H * pos_S;
    pos_R = pos_R./pos_R(3);
    
    % display
    figure(1),
    subplot(1,2,1);
    imshow(S),title('Source Frame'),hold on;
    draw_frame(pos_S);
    
    subplot(1,2,2);
    imshow(R),title('Reference Frame'),hold on;
    draw_frame(pos_R);
end

function draw_frame(pos)
    from = [1,1,1,1];
    to = [2,3,4,1];
    fromX = pos(1,from)';
    toX = pos(1,to)';
    fromY = pos(2,from)';
    toY = pos(2,to)';
    
    h = line([fromX; toX], [fromY; toY]);
    set(h,'linewidth', 2, 'color', 'r') ;
end

function H = homography(pts_R, pts_S)
% Compute homography using 4 pairs of matching points that maps from 
% pts_S to pts_R using least squares solver.
%
% Input: 
%     pts_R - reference homogeneous coordinates 
%     pts_S - projected homogeneous coordinates
% Output: 
%     H - 3x3 matrix, such that pts_S ~= H*pts_R

    % Normalize homogeneous coordinates
    T_ = normalizeTransform(pts_R);
    T = normalizeTransform(pts_S);
    X_ = T_ * pts_R;
    X = T * pts_S;

    % Construct A and compute H
    len = size(X_,2);
    A = zeros(2*len,9);
    for i = 1: len
        u = X(1,i);
        v = X(2,i);
        u_ = X_(1,i);
        v_ = X_(2,i);

        A(2*i-1,:) =    [-u, -v, -1,    0,  0,  0,   u*u_, v*u_, u_];
        A(2*i,:) =      [ 0,  0,  0,   -u, -v, -1,   u*v_, v*v_, v_];
    end
    if sum(isinf(A)+isnan(A)) >0
        H = [];
    else
        [~, ~, V] = svd(A);
        Hn = V(:,end);
        Hn = reshape(Hn,[3,3])';

        % Unnormalize
        T_inv = T_\eye(3);
        H = T_inv * Hn * T;
    end
end

function T = normalizeTransform(pts)
    u = pts(2,:);
    v = pts(1,:);
    n = numel(u);

    aver_u = mean(u);
    aver_v = mean(v);
    den = real(sqrt((u-aver_u).^2 + (v-aver_v).^2));
    den = sum(den);
    sigma = sqrt(2)*n /den;

    T = sigma.*[1,0,-aver_u;
                0,1,-aver_v;
                0,0,1/sigma];
end

