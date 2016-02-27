%% Setup environment and read test image
close all; clear; clc;
img_id = 1;
img_addr = ['imgs/', sprintf('%02d',img_id), '.jpg'];

img = im2double(rgb2gray(imread(img_addr)));
[h,w,~] = size(img);
figure(),imshow(img);

%% Upsampling Kernel Size
% Settings
sigma = 2;                      % Initial Sigma Size
maxR = 35;                      % Max Region to Detect
n = 10;                         % Iterative Times
k = nthroot(maxR/sqrt(2),n);    % Kernel Factor
display = true;                 % Show plots

[img_space_1,scl_space_1] = up_kernel(img,sigma,k,n,display);
[img_space,scl_space] = sub_figure(img,sigma,k,n,display);

%% Find correspond scale