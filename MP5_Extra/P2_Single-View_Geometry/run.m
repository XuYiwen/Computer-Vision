clear; clc; close all;

imgPath = 'CSL.jpg'; 
img = imread(imgPath);

vp = getVanishingPoint(img);