%% Setup environment and read in images
close all; clear; clc;

img_id = 1;
sigma_id =  {2,     2,      2,      2};
maxR_id =   {55,    60,     55,     55};
n_id =      {10,    10,     10,     10};
rad_id =    {2,     2,      2,      3};
pct_id =    {0.04,  0.03,   0.12,   0.15};

img_addr = ['imgs/', sprintf('%02d',img_id), '.jpg'];
img = im2double(rgb2gray(imread(img_addr)));
[h,w,~] = size(img);

%% Upsampling Kernel Size
% Settings
sigma = sigma_id{img_id};                           % Initial Sigma Size
maxR = maxR_id{img_id};                             % Max Region to Detect
n = n_id{img_id};                                   % Iterative Times
spc_mtd = 'dog';                                    % Method: 'sub', 'upk', 'dog'
k = nthroot(maxR/sqrt(2)/sigma,n);                  % Kernel Factor
display = true;                                     % Show plots

if (strcmp(spc_mtd,'upk'))
    [img_space,scl_space] = up_kernel(img,sigma,k,n,display);
elseif (strcmp(spc_mtd,'sub')) 
    [img_space,scl_space] = sub_figure(img,sigma,k,n,display);
elseif (strcmp(spc_mtd,'dog'))
    [img_space,scl_space] = DoG(img,sigma,maxR,3,display);
else error('Wrong Method');  
end

%% Nonmaximun Suppression and Scale-fitting
% Settings
rad = rad_id{img_id};                               % Radius in Nonmaximum suppression(1~3);
pct = pct_id{img_id};                               % Threshold in max precentage
maxi_mtd = 'ordfilt2';                              % Method: 'ordfilt2', 'colfilt', 'nlfilter'
th = pct * max(img_space(:));                       % Threshold response

% Slidewise Nonmaximum Suppression
maxi_space = img_space;
sz = 2*rad+1;
t_start = tic;
for i = 1:size(img_space,3)
	if (strcmp(maxi_mtd,'ordfilt2')) 
        maxi_space(:,:,i) = ordfilt2(img_space(:,:,i),sz^2,ones(sz));
    elseif (strcmp(maxi_mtd,'colfilt')) 
        maxi_space(:,:,i) = colfilt(img_space(:,:,i),[sz,sz],'sliding',@max); 
    elseif (strcmp(maxi_mtd,'nlfilter')) 
        fun = @(x) max(x(:));
        maxi_space(:,:,i) = nlfilter(img_space(:,:,i),[sz,sz],fun); 
    end
end
t = toc(t_start);
fprintf('Running Time - %s: %6.6f s\n',maxi_mtd,t);

% Third Dimension Nonmaximum Suppression
x =[]; y = []; r = [];
for i = 1:size(img_space,3)
    cur = maxi_space(:,:,i);
    cur_up = ones(size(cur)); cur_down = ones(size(cur));
    if (i>1) up = maxi_space(:,:,i-1); cur_up = (cur-up)>0; end
    if (i<n) down = maxi_space(:,:,i+1); cur_down = (cur-down)>0; end
    at_max_level = (cur_up) & (cur_down);
    
    im = img_space(:,:,i); 
    at_max_center = (im == cur) & (im > th);
    
    cim = at_max_level .* at_max_center;
    
    [cx,cy] = find(cim); 
    cr = ones(size(cx)).*scl_space(i);
    x = [x;cx]; y = [y;cy]; r = [r;cr];
end
figure(4),show_all_circles(img, y, x, r);
