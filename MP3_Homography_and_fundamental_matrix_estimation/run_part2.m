%% Fundamental Matrix Estimation (ground truth match)
close all; clear; clc;

% load images and match files
pair = 'house';
img_R = imread(sprintf('imgs/part2/%s1.jpg',pair));
img_S = imread(sprintf('imgs/part2/%s2.jpg',pair));
matches = load(sprintf('imgs/part2/%s_matches.txt',pair));

% get matches pair
N = size(matches,1);
pos_R = [matches(:,1),matches(:,2),ones(N,1)];
pos_S = [matches(:,3),matches(:,4),ones(N,1)];
show_matches(img_R,pos_R',img_S,pos_S','funda');

% fit fundamental and compute error;
if true
    F = fit_fundamental(pos_R,pos_S,false); % without normalize
    pos_S_ = (F * pos_R')'; 
    [aver_dist,~] = check_fundamental(pos_S_,pos_S,true);
    show_estimate(pos_S_,pos_S,img_S,sprintf('%s-%s',pair,'disnormal'));
% else
    F = fit_fundamental(pos_R,pos_S,true); % with normalize
    pos_S_ = (F * pos_R')'; 
    [aver_dist,dist] = check_fundamental(pos_S_,pos_S,true);
    show_estimate(pos_S_,pos_S,img_S,sprintf('%s-%s',pair,'normal'));
end

pause;
%% Fundamental Matrix Estimation (putative match)
close all; clear; clc;

% load images and match files
pair = 'library';
img_R = imread(sprintf('imgs/part2/%s1.jpg',pair));
img_S = imread(sprintf('imgs/part2/%s2.jpg',pair));

% Extract features from both images
method = 'harris';
disp('>>>> Extract Features');
[keypt_R,des_R] = get_feature(img_R,method,true,['refer_',pair]);
[keypt_S,des_S] = get_feature(img_S,method,true,['source_',pair]);

num_matches = 300;
dis = dist2(des_R,des_S);
top = sort(dis(:)); 
th = top(min(num_matches,numel(dis)));
[sR,sS] = find(dis<=th);
matches = [sR,sS]';

% pair matches to homogenous coordinates
pos_R = keypt_R(matches(1,:),1:2)' ; pos_R(3,:) = 1 ; pos_R = pos_R';
pos_S = keypt_S(matches(2,:),1:2)' ; pos_S(3,:) = 1 ; pos_S = pos_S';
show_matches(img_R,pos_R',img_S,pos_S','funda_RANSAC_pre');

% Automatic homography estimation with RANSAC
disp('>>>> Perform RANSAC');
iter = 5000;
best_fit = 0;
for t = 1: iter
    % estimate homograpyh using rand 4 pairs
    subset = randsample(size(matches,2),4);
    pts_R = pos_R(subset,:);
    pts_S = pos_S(subset,:);

    Ftemp = fit_fundamental(pos_R,pos_S,true);
    if isempty(Ftemp)
        continue;
    end

    % check fundamental fitting error
    pos_S_ = (Ftemp * pos_R')'; 
    [~,dist] = check_fundamental(pos_S_,pos_S,false);
    inlier =dist < 2;
    num_inlier = sum(inlier);

    % update best fit and compute average residual;
    if num_inlier > best_fit
        best_fit = num_inlier;
        Fopt = Ftemp;

        idx = find(inlier);
        in_pos_R = pos_R(idx,:);
        in_pos_S = pos_S(idx,:);
        aver_res = sum(dist(idx))/num_inlier;
    end
end
fprintf('Num of Inliers - %d \n',best_fit);
pos_S_ = (Fopt * pos_R')'; 
[aver_dist,~] = check_fundamental(pos_S_,pos_S,true);
show_matches(img_R,pos_R',img_S,pos_S','funda_RANSAC_post');
show_estimate(pos_S_,pos_S,img_S,sprintf('%s-%s',pair,'RANSAC'));

% recompute using inlier matches;
pos_R = in_pos_R;
pos_S = in_pos_S;
F = fit_fundamental(pos_R,pos_S,true);
pos_S_ = (F * pos_R')';
[aver_dist,~] = check_fundamental(pos_S_,pos_S,true);
show_matches(img_R,pos_R',img_S,pos_S','funda_RANSAC_re');
show_estimate(pos_S_,pos_S,img_S,sprintf('%s-%s',pair,'RANSAC_re'));

pause;

%% Triangulation
close all; clear; clc;

% get camera projection matrix and match pair
pair = 'house';
P1 = load(sprintf('imgs/part2/%s1_camera.txt',pair));
P2 = load(sprintf('imgs/part2/%s2_camera.txt',pair));
matches = load(sprintf('imgs/part2/%s_matches.txt',pair));
N = size(matches,1);
X1 = [matches(:,1),matches(:,2),ones(N,1)];
X2 = [matches(:,3),matches(:,4),ones(N,1)];

% world coordinates for matching points
X =[];
for k = 1:N
    % construct least square equation
    x1 = X1(k,:);
    x1_cp = cross_product_matrix(x1,P1);
    x2 = X2(k,:);
    x2_cp = cross_product_matrix(x2,P2);
    A = [x1_cp; x2_cp];
    
    % solve for X and homogeneous coordinates convert
    [~,~,V] = svd(A);
    Xhomo=reshape(V(:,end), 1, 4)';
    Xcur = Xhomo(1:3)./Xhomo(4);
    
    X = [X,Xcur];
end

% camera coordinates
[~,~,V] = svd(P1);
    C1=reshape(V(:,end), 1, 4)';
    Cam1 = C1(1:3)./C1(4);
[~,~,V] = svd(P2);
    C2=reshape(V(:,end), 1, 4)';
    Cam2 = C2(1:3)./C2(4);

% display
figure();
plot3(X(1,:),X(2,:),X(3,:),'r.'),axis equal, hold on;
plot3(Cam1(1),Cam1(2),Cam1(3),'b*'),axis equal, hold on;
plot3(Cam2(1),Cam2(2),Cam2(3),'b*'),axis equal, hold off;
pause;
