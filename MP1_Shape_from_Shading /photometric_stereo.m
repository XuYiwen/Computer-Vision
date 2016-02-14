function [albedo_image, surface_normals] = photometric_stereo(imarray, light_dirs)
% imarray: h x w x Nimages array of Nimages no. of images
% light_dirs: Nimages x 3 array of light source directions
% albedo_image: h x w image
% surface_normals: h x w x 3 array of unit surface normals

% reshape parts of linear square equation
[h,w,n]=size(imarray);
intensity = reshape(imarray,h*w,n)';
source = light_dirs;
g = source\intensity;

% seperate albedo and surface normal
albedo = sqrt(sum(g.^2));
normals = g./repmat(albedo,[3,1]);
albedo_image = reshape(albedo,[h,w]);
surface_normals = reshape(normals',[h,w,3]);
end

