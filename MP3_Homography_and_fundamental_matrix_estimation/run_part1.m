% Stitching pairs of images

close all; clear; clc;

Xdata = [-35,800];
Ydata = [-20,420];
img_pair = 'uttower';

% put reference image onto base plane
R = im2double(imread('imgs/left.jpg'));
    R = imresize(R,0.5);
    Ho = homography_estimate(R,R,false);
    To = maketform('projective', Ho'); 
    base = imtransform(R, To, 'XData',Xdata,'YData',Ydata); 

% add source image to reference plane
Sl = im2double(imread('imgs/right.jpg'));
    Sl = imresize(Sl,0.5);
    H = homography_estimate(R,Sl,true);
    T = maketform('projective', H'); 
    toadd = imtransform(Sl, T, 'XData',Xdata,'YData',Ydata);

% Neighboring image stitch
output = neighbor_stitch(toadd,base,base);
figure(),imshow(output),title('pair image stitch');
    fig = gcf;
    fig.PaperPositionMode = 'auto';
    capture = ['out/', sprintf('%s-pair_stitch',img_pair)];
    print(capture,'-dpng','-r0');
      

