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

%% Part 1: Find out ground line
vp1 = homo2pixel(vp_x);
vp2 = homo2pixel(vp_z);
ground = real(cross(vp1,vp2));
ground = normalize_line(ground);

% report ground line
fprintf('>>> Ground Line\n');
fprintf('[Ground Line] %.1f x + %.1f y + % .1f = 0\n', ground(1),ground(2),ground(3));

% plot ground line
figure(2),
% show image
hold off, imagesc(img);
% expand to vanishing points
hold on,
bx1 = min([1, vp1(1), vp2(1)])-10; bx2 = max([size(img,2), vp1(1), vp2(1)])+10;
by1 = min([1, vp1(2), vp2(2)])-10; by2 = max([size(img,1), vp1(2), vp2(2)])+10;
% get endpoints for ground line
if ground(1)<ground(2)
    pt1 = real(cross([1 0 -bx1]', ground));
    pt2 = real(cross([1 0 -bx2]', ground));
else
    pt1 = real(cross([0 1 -by1]', ground));
    pt2 = real(cross([0 1 -by2]', ground));
end
pt1 = pt1/pt1(3);
pt2 = pt2/pt2(3);
plot([pt1(1) pt2(1)], [pt1(2) pt2(2)], 'g', 'Linewidth', 1);
% plot 2 vanishing points
plot(vp1(1), vp1(2), '*r');
plot(vp2(1), vp2(2), '*r');
axis image
axis([bx1 bx2 by1 by2]); 
title('Ground Line Estimation');
    set(gcf,'position',[1 500 1000 400]);
    set(gcf,'PaperPositionMode','auto');
    print(2, 'ground_line.png', '-dpng') ;

%% Part 2: Solve for focal length and principle points
vp1 = homo2pixel(vp_x);
vp2 = homo2pixel(vp_y);
vp3 = homo2pixel(vp_z);
vp = [vp1, vp2, vp3];

% compute focal length and principle
syms f  u  v
K = [ f, 0, u; 0, f, v; 0, 0, 1];         
T = inv(K)' * inv(K);

eqn1 = vp(:,1)' * T * vp(:,2) == 0;
eqn2 = vp(:,1)' * T * vp(:,3) == 0;
eqn3 = vp(:,2)' * T * vp(:,3) == 0;

solution = solve(eqn1, eqn2, eqn3, f, u, v);
f  = single(solution.f);
u = single(solution.u);
v = single(solution.v);

% report focal length
fprintf('>>> Camera Parameters\n');
fprintf('[f]: %.1f\n',abs(f));
fprintf('[u]: %.1f\n',u);
fprintf('[v]: %.1f\n',v);

% plot
figure(3),
% show image
hold off, imagesc(img);
% expand to vanishing points
hold on, plot(u, v, '*r');
axis image
title('Camera Principle Points');
    set(gcf,'PaperPositionMode','auto');
    print(3, 'camera.png', '-dpng') ;

%% Part 3: Rotation Matrix
K = [ f, 0, u; 0, f, v; 0, 0, 1];  
r1 = K \ vp1; r1 =r1/norm(r1);
r2 = K \ vp2; r2 =r2/norm(r2);
r3 = K \ vp3; r3 =r3/norm(r3);
fprintf('>>> Rotation Matrix\n');
R = [r1,r2,r3]

%% Part 4: Height Estimation
refer_h = 6;
estimateHeight(img, ground, vp3,  'CSL' ,refer_h);
estimateHeight(img, ground, vp3,  'lamp', refer_h);
estimateHeight(img, ground, vp3,  'spike', refer_h);