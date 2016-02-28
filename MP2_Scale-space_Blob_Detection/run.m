%% Setup environment and read test image
close all; clear; clc;
img_id = 1;
img_addr = ['imgs/', sprintf('%02d',img_id), '.jpg'];

img = im2double(rgb2gray(imread(img_addr)));
[h,w,~] = size(img);
% figure(),imshow(img);

%% Upsampling Kernel Size
% Settings
sigma = 2;                      % Initial Sigma Size
maxR = 30;                      % Max Region to Detect
n = 10;                         % Iterative Times
k = nthroot(maxR/sqrt(2),n);    % Kernel Factor
display = true;                 % Show plots

% [img_space,scl_space] = up_kernel(img,sigma,k,n,display);
[img_space,scl_space] = sub_figure(img,sigma,k,n,display);

%% Nonmaximun Suppression and Scale-fitting
% Settings
rad = 2;                        % Radius in Nonmaximum suppression(1~3);
th = 0.02 * max(img_space(:));  % Threshold response

% Slidewise Nonmaximum Suppression
for i = 1:n
    im = img_space(:,:,i);
    sz = 2*rad+1;                            % Size of mask.
	maxi = ordfilt2(im,sz^2,ones(sz));       % Grey-scale dilate.
	im = (im==maxi)&(im>th);                 % Find maxima.
    img_space(:,:,i) = im;
end

% Third Dimension Nonmaximum Suppression
x =[]; y = []; r = [];
for i = 2:n-1
    up = img_space(:,:,i-1);
    im = img_space(:,:,i);
    down = img_space(:,:,i+1);
    mask = (im-up>0) & (im-down>0);
    
    [cx,cy] = find(mask); 
    cr = ones(size(cx)).*scl_space(i);
    x = [x;cx]; y = [y;cy]; r = [r;cr];
end
figure(4),show_all_circles(img, y, x, r);
set(gcf,'position',[1 500 2*w 2*h]);


