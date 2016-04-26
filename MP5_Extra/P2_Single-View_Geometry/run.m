clear; clc; close all;

imgPath = 'CSL.jpg'; 
img = imread(imgPath);
userInput = false;

%% Load input of 3 vanishing points
if userInput
    good = false;
    while ~good
        disp('>>> Vanishing Point for Z direction (left-most)');
        vp_z = getVanishingPoint(img,'Z');
        
        prompt = 'Good with the results? y/n [y]: ';
        key = input(prompt,'s');
        if key == 'y'
            good = true;
        end
    end

    good = false;
    while ~good
        disp('>>> Vanishing Point for X direction (right-most)');
        vp_x = getVanishingPoint(img,'X');
        
        prompt = 'Good with the results? y/n [y]: ';
        key = input(prompt,'s');
        if key == 'y'
            good = true;
        end
    end
    
    good = false;
    while ~good
        disp('>>> Vanishing Point for Y direction (vertical)');
        vp_y = getVanishingPoint(img,'Y');
        
        prompt = 'Good with the results? y/n [y]: ';
        key = input(prompt,'s');
        if key == 'y'
            good = true;
        end
    end
    save('vp_record.mat','vp_z','vp_x','vp_y');
else
    load('vp_record.mat','vp_z','vp_x','vp_y');
end

% report vanishing points in pixels
clc;
fprintf('>>> Vanishing Points\n');
fprintf('[X]:[%.1f,%.1f,%.1f]\n',vp_x(1)/vp_x(3),vp_x(2)/vp_x(3),vp_x(3)/vp_x(3));
fprintf('[Y]:[%.1f,%.1f,%.1f]\n',vp_y(1)/vp_y(3),vp_y(2)/vp_y(3),vp_y(3)/vp_y(3));
fprintf('[Z]:[%.1f,%.1f,%.1f]\n',vp_z(1)/vp_z(3),vp_z(2)/vp_z(3),vp_z(3)/vp_z(3));

%% Find out ground line
vp1 = homo2pixel(vp_x);
vp2 = homo2pixel(vp_z);
ground_line = real(cross(vp1,vp2));
figure();

%%