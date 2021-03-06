%% Spring 2014 CS 543 Assignment 1
%% Arun Mallya and Svetlana Lazebnik

% path to the folder and subfolder
close all,clear ,clc;
root_path = 'croppedyale/';
subject_name = 'yaleB05';

% integration_method = {'column', 'row', 'average', 'random','onedim-random'};
integration_method = {'column'};

save_flag = 0; % whether to save output images

%% load images
full_path = sprintf('%s%s/', root_path, subject_name);
[ambient_image, imarray, light_dirs] = LoadFaceImages(full_path, subject_name, 64);
image_size = size(ambient_image);

%% preprocess the data
for id = 1:size(imarray,3)
    cur = imarray(:,:,id);
    cur = cur - ambient_image;
    mask = double(cur > 0);
    cur = cur.*mask;
    imarray(:,:,id) = cur/255;
end

%% get albedo and surface normals
[albedo_image, surface_normals] = photometric_stereo(imarray, light_dirs);

%% reconstruct height map
for i = 1:size(integration_method)
    
    tstart = tic;
    height_map = get_surface(surface_normals, integration_method{i});
    t_end = toc(tstart);
    time{i} = t_end;
    
    display_output(albedo_image, height_map,true,integration_method{i});
    plot_surface_normals(surface_normals,true);
end
% time

%% save output (optional) -- note that negative values in the normal images will not save correctly!
if save_flag
    imwrite(albedo_image, sprintf('%s_albedo.jpg', subject_name), 'jpg');
    imwrite(surface_normals, sprintf('%s_normals_color.jpg', subject_name), 'jpg');
    imwrite(surface_normals(:,:,1), sprintf('%s_normals_x.jpg', subject_name), 'jpg');
    imwrite(surface_normals(:,:,2), sprintf('%s_normals_y.jpg', subject_name), 'jpg');
    imwrite(surface_normals(:,:,3), sprintf('%s_normals_z.jpg', subject_name), 'jpg');    
end

