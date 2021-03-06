% Affine Facterization
clear; clc;

%% Loading data
dataPath = fullfile('data','measurement_matrix.txt');
measure_mat = load(dataPath);
M = size(measure_mat,1)/2; % number of cameras/images
N = size(measure_mat,2);   % number of 3D points

%% Centering
centered_mat = zeros(size(measure_mat));
mean_mat = zeros(size(measure_mat));
for i = 1:M
    init_x = measure_mat(2*i-1,:);
    init_y = measure_mat(2*i,:);
    
    mean_x = mean(init_x);
    mean_y = mean(init_y);
    
    centered_mat(2*i-1,:) = init_x - mean_x;
    centered_mat(2*i,:) = init_y - mean_y;
    mean_mat(2*i-1,:) = mean_x;
    mean_mat(2*i,:) = mean_y;
end

%% Factorize D
[U,W,V] = svd(centered_mat);
U = U(:,1:3);
W = W(1:3,1:3);
V = V(:,1:3);

%% Create Motion and Shape matrices
motion = U;
shape = W*V';

%% Elimimate affine ambiguity
A = zeros(3*M,9);
b = zeros(3*M,1);
for i = 1:M
    Ax = motion(2*i-1,:);
    Ay = motion(2*i,:);
    
    xx = Ax' * Ax; 
    xy = Ax' * Ay; 
    yy = Ay' * Ay;
    
    A((i-1)*3+1,:) = xx(:);
    A((i-1)*3+2,:) = xy(:);
    A((i-1)*3+3,:) = yy(:);
    
    b((i-1)*3+1,:) = 1;
    b((i-1)*3+2,:) = 0;
    b((i-1)*3+3,:) = 1;
end
CC = A\b;
CC = reshape(CC,[3,3]);

% Choleskey Decomposition
CC = nearestSPD(CC);
C = chol(CC,'lower');
% C = CC;
motion = motion * C;
shape = C \ shape;

%% Analysis of accuracy
predict_mat = motion * shape + mean_mat;
error = predict_mat - measure_mat;
ex = error(1:2:2*M,:);
ey = error(2:2:2*M,:);
residual = ex.*ex + ey.*ey;

frame_residual = sum(residual,2);
total_residual = sum(frame_residual,1);
fprintf('Total Residual for all frames: %.2f pixels\n',total_residual);
fprintf('Average Residual per frame: %.2f pixels\n',total_residual/M);

%% Display
% 3D plot
figure(1);
plot3(shape(1,:),shape(2,:),shape(3,:),'.');

% Residual of each image
figure(2),
    set(gcf,'position',[1 500 500 400]);
    set(gcf,'PaperPositionMode','auto');
    plot((1:M)',frame_residual,'r.-');
    title('residual for each frame');
print(2, 'residual.png', '-dpng') ;    
    
    
% Estimate distance
pick = randperm(M); 
pick = pick(1:3);
pick_x = 2*pick-1;
pick_y = 2*pick;

figure(3),
    set(gcf,'position',[1 500 1800 500]);
    set(gcf,'PaperPositionMode','auto');
    
    for i = 1: numel(pick)
        img = imread(fullfile('data',sprintf('frame%08d.jpg',pick(i))));
        mx = measure_mat(pick_x(i),:);
        my = measure_mat(pick_y(i),:);
        px = predict_mat(pick_x(i),:);
        py = predict_mat(pick_y(i),:);
        
        subplot(1,numel(pick),i),imshow(img),hold on;
        plot(mx,my,'rx'),hold on;
        plot(px,py,'b*'),hold off;
    end
print(3, 'results.png', '-dpng') ;
