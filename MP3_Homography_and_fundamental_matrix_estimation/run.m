%% Stitching pairs of images

% close all; clear; clc;
% 
% Xdata = [-35,800];
% Ydata = [-20,420];
% img_pair = 'uttower';
% 
% % put reference image onto base plane
% R = im2double(imread('imgs/left.jpg'));
%     R = imresize(R,0.5);
%     Ho = homography_estimate(R,R,false);
%     To = maketform('projective', Ho'); 
%     base = imtransform(R, To, 'XData',Xdata,'YData',Ydata); 
% 
% % add source image to reference plane
% Sl = im2double(imread('imgs/right.jpg'));
%     Sl = imresize(Sl,0.5);
%     H = homography_estimate(R,Sl,true);
%     T = maketform('projective', H'); 
%     toadd = imtransform(Sl, T, 'XData',Xdata,'YData',Ydata);
% 
% % Neighboring image stitch
% output = neighbor_stitch(toadd,base,base);
% figure(),imshow(output),title('pair image stitch');
%     fig = gcf;
%     fig.PaperPositionMode = 'auto';
%     capture = ['out/', sprintf('%s-pair_stitch',img_pair)];
%     print(capture,'-dpng','-r0');
      
%% Extra - panorama stitching

% close all; clear; clc;
% 
% Xdata = [-300,750];
% Ydata = [-20,400];
% 
% pano_num = 3;
% pano_set= {'hill','ledge','pier'};
% folder = ['imgs/',pano_set{pano_num}];
% 
% % compute homography to center image
% R = im2double(imread(sprintf('%s/%1d.JPG',folder,2)));
%     Ho = homography_estimate(R,R,false);
%     To = maketform('projective', Ho'); 
%     base = imtransform(R, To, 'XData',Xdata,'YData',Ydata); 
%     
% Sl = im2double(imread(sprintf('%s/%1d.JPG',folder,1)));
%     Hl = homography_estimate(R,Sl,false);
%     Tl = maketform('projective', Hl'); 
%     left = imtransform(Sl, Tl, 'XData',Xdata,'YData',Ydata); 
% 
% Sr = im2double(imread(sprintf('%s/%1d.JPG',folder,3)));
%     Hr = homography_estimate(R,Sr,false);
%     Tr = maketform('projective', Hr'); 
%     right = imtransform(Sr, Tr, 'XData',Xdata,'YData',Ydata);
% 
% % combine panorama
% base = neighbor_stitch(left,base,base);
% output = neighbor_stitch(right,base,base);
% figure(),imshow(output),title('panorama stitch');
%     fig = gcf;
%     fig.PaperPositionMode = 'auto';
%     capture = ['out/', sprintf('%s-pano_stitch',pano_set{pano_num})];
%     print(capture,'-dpng','-r0');

%% Fundamental Matrix Estimation and Triangulation
