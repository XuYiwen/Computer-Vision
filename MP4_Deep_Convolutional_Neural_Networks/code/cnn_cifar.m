% function are called with two types
% either cnn_cifar('coarse') or cnn_cifar('fine')
% coarse will classify the image into 20 catagories
% fine will classify the image into 100 catagories
function cnn_cifar(type, varargin)

if ~(strcmp(type, 'fine') || strcmp(type, 'coarse')) 
    error('The argument has to be either fine or coarse');
end

% initial
close all; clc;
expName = 'net2-1e-2224-5_5-crop';
%% --------------------------------------------------------------------
%                                                         Set parameters
% --------------------------------------------------------------------
%
% data directory
opts.dataDir = fullfile('cifar_data','cifar') ;
% experiment result directory
opts.expDir = fullfile('cifar_data',expName) ;
% image database
opts.imdbPath = fullfile('cifar_data', 'imdb.mat');
% log file path
opt.logDir = fullfile(opts.expDir,'log.txt');
% confusion matrix output path
opt.cfmDir = fullfile(opts.expDir,'cifar_confusion_matrix.png');
% prediction csv
opt.predictDir = fullfile(opts.expDir,'cifar_prediction.csv');

if (~exist(opts.expDir,'dir'))
    mkdir(opts.expDir);    
end

% % set up the batch size (split the data into batches)
% opts.train.batchSize = 100 ;
% % number of Epoch (iterations)
% opts.train.numEpochs = 15 ;
% % resume the train
% opts.train.continue = true ;
% % use the GPU to train
% opts.train.useGpu = true ;
% % set the learning rate
% opts.train.learningRate = [0.001*ones(1, 10) 0.0001*ones(1,15)] ;
% % set weight decay
% opts.train.weightDecay = 0.0005 ;
% % set momentum
% opts.train.momentum = 0.9 ;
% % experiment result directory
% opts.train.expDir = opts.expDir ;
% % parse the varargin to opts. 
% % If varargin is empty, opts argument will be set as above
% opts = vl_argparse(opts, varargin);

% set up the batch size (split the data into batches)
opts.train.batchSize = 100 ;
% resume the train
opts.train.continue = true ;
% use the GPU to train
opts.train.useGpu = true ;
% set the learning rate
opts.train.learningRate = [0.001*ones(1, 10) 0.0001*ones(1,15) 0.00001*ones(1,15)] ;
% number of Epoch (iterations)
% opts.train.numEpochs = size(opts.train.learningRate,2) ;
opts.train.numEpochs = 15;
% set weight decay
opts.train.weightDecay = 0.0005 ;
% set momentum
opts.train.momentum = 0.9 ;
% experiment result directory
opts.train.expDir = opts.expDir ;
% parse the varargin to opts. 
% If varargin is empty, opts argument will be set as above
opts = vl_argparse(opts, varargin);

% --------------------------------------------------------------------
%                                                         Prepare data
% --------------------------------------------------------------------

% record the time
tic
diary(opt.logDir);
% load data
imdb = load(opts.imdbPath) ;

%% Define network 
% The part you have to modify
net.layers = {} ;

% 1 conv1
net.layers{end+1} = struct('type', 'conv', ...
  'filters', 1e-2*randn(5,5,3,30, 'single'), ...
  'biases', zeros(1, 30, 'single'), ...
  'filtersLearningRate', 1, ...
  'biasesLearningRate', 2, ...
  'stride', 1, ...
  'pad', 2) ;

% 8 relu
net.layers{end+1} = struct('type', 'relu') ;

% 2 pool1 (max pool)
net.layers{end+1} = struct('type', 'pool', ...
                           'method', 'max', ...
                           'pool', [2 2], ...
                           'stride', 2, ...
                           'pad', [0 0 0 0]) ;
                       
% 3 conv2
net.layers{end+1} = struct('type', 'conv', ...
  'filters', 1e-2*randn(5,5,30,30, 'single'), ...
  'biases', zeros(1, 30, 'single'), ...
  'filtersLearningRate', 1, ...
  'biasesLearningRate', 2, ...
  'stride', 1, ...
  'pad', 2) ;

% 8 relu
net.layers{end+1} = struct('type', 'relu') ;

% 4 pool2 (max pool)
net.layers{end+1} = struct('type', 'pool', ...
                           'method', 'max', ...
                           'pool', [2 2], ...
                           'stride', 2, ...
                           'pad', [0 0 0 0]) ;
                       
% 5 conv3
net.layers{end+1} = struct('type', 'conv', ...
  'filters', 1e-2*randn(5,5,30,30, 'single'), ...
  'biases', zeros(1, 30, 'single'), ...
  'filtersLearningRate', 1, ...
  'biasesLearningRate', 2, ...
  'stride', 1, ...
  'pad', 2) ;

% 8 relu
net.layers{end+1} = struct('type', 'relu') ;

% 9 pool4 (avg pool)
net.layers{end+1} = struct('type', 'pool', ...
                           'method', 'avg', ...
                           'pool', [2 2], ...
                           'stride', 2, ...
                           'pad', [0 0 0 0]) ; 
                      
% 10 conv5 (fully connected)
net.layers{end+1} = struct('type', 'conv', ...
                           'filters', 1e-4*randn(4,4,30,100, 'single'),...
                           'biases', zeros(1,100,'single'), ...
                           'filtersLearningRate', 1, ...
                           'biasesLearningRate', 2, ...
                           'stride', 1, ...
                           'pad', 0) ;
% 11 loss
net.layers{end+1} = struct('type', 'softmaxloss') ;



% --------------------------------------------------------------------
%                                                                Train
% --------------------------------------------------------------------

% Take the mean out and make GPU if needed
m_img = mean(imdb.images.data,4);
imdb.images.data = bsxfun(@minus, imdb.images.data, m_img) ;
if opts.train.useGpu
%   imdb.images.data = gpuArray(imdb.images.data) ;
end
%% display the net
vl_simplenn_display(net);
%% start training
[net,info] = cnn_train_cifar(net, imdb, @getBatch, ...
    opts.train, ...
    'val', find(imdb.images.set == 2) , 'test', find(imdb.images.set == 3)) ;
%% Record the result into csv and draw confusion matrix
load(fullfile(opts.expDir, ['net-epoch-' int2str(opts.train.numEpochs) '.mat']));
load(opts.imdbPath);
fid = fopen(opt.predictDir, 'w');
strings = {'ID','Label'};
for row = 1:size(strings,1)
    fprintf(fid, repmat('%s,',1,size(strings,2)-1), strings{row,1:end-1});
    fprintf(fid, '%s\n', strings{row,end});
end
fclose(fid);
ID = 1:numel(info.test.prediction_class);
dlmwrite(opt.predictDir,[ID', info.test.prediction_class], '-append');

val_groundtruth = images.labels(45001:end);
val_prediction = info.val.prediction_class;
val_confusionMatrix = confusion_matrix(val_groundtruth , val_prediction);
cmp = jet(50);
figure ;
imshow(ind2rgb(uint8(val_confusionMatrix),cmp));
imwrite(ind2rgb(uint8(val_confusionMatrix),cmp) , opt.cfmDir);
toc
diary('off');

% --------------------------------------------------------------------
%% call back function get the part of the batch
function [im, labels] = getBatch(imdb, batch , set)
% --------------------------------------------------------------------
im = imdb.images.data(:,:,:,batch);
[h,w,~,n] = size(im);
crop_size = 4;

% data augmentation
if set == 1 % training
    for i = 1: n
        img = im(:,:,:,i);
        
        % zoom in image
        img = imresize(img,[h+crop_size,w+crop_size]);

%         % randomly flip image
%         if (rand > 0.5)
%             img = flip(img,round(rand)+1);
%         end
        
%         % adding noise
%         if(rand > 0.8)
%             img = imnoise(img,'salt & pepper',0.005);
%         end
%         
        % random cropping image
        rand_ori = rand(1,2).*(crop_size+1);
        rx = ceil(rand_ori(1));
        ry = ceil(rand_ori(2));
        img = img(rx:rx+(h-1),ry:ry+(w-1),:);
        
        % put the augmented image back
        im(:,:,:,i) = im2single(img);
    end
    
%     % display getBatch
%     figure(4);
%     pick = randperm(size(im,4));
%     pick = pick(1:4);
%     set(gcf,'position',[1 500 1500 500]);
%     set(gcf,'PaperPositionMode','auto');
%     for i = 1:4
%         t = pick(i);
%         subplot(1,4,i), imshow(im(:,:,:,i));
%     end
%     print(1, 'getBatch.png', '-dpng') ;
end


if set ~= 3
    labels = imdb.images.labels(1,batch) ;
end



