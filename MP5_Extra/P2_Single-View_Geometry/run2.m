clear; clc; close all;

imgPath = 'CSL.jpg'; 
img = imread(imgPath);
userInput = false;

%% Load input of 3 vanishing points
load('vp_record.mat','vp_z','vp_x','vp_y');

%% Part 4: Height Estimation
% CSL building

% spike statue
% lamp
