function [net, info] = cnn_train_cifar(net, imdb, getBatch, varargin)
% CNN_TRAIN   Demonstrates training a CNN
%    CNN_TRAIN() is an example learner implementing stochastic gradient
%    descent with momentum to train a CNN for image classification.
%    It can be used with different datasets by providing a suitable
%    getBatch function.

opts.train = [] ;
opts.val = [] ;
opts.test = [];
opts.numEpochs = 300 ;
opts.batchSize = 256 ;
opts.useGpu = true ;
opts.learningRate = 0.001 ;
opts.continue = false ;
opts.expDir = fullfile('data','exp') ;
opts.conserveMemory = false ;
opts.sync = true ;
opts.prefetch = false ;
opts.weightDecay = 0.0005 ;
opts.momentum = 0.9 ;
opts.errorType = 'multiclass' ;
opts.plotDiagnostics = false ;
opts = vl_argparse(opts, varargin) ;
if ~exist(opts.expDir, 'dir'), mkdir(opts.expDir) ; end
if isempty(opts.train), opts.train = find(imdb.images.set==1) ; end
if isempty(opts.val), opts.val = find(imdb.images.set==2) ; end
if isnan(opts.train), opts.train = [] ; end

% -------------------------------------------------------------------------
%                                                    Network initialization
% -------------------------------------------------------------------------

for i=1:numel(net.layers)
  if ~strcmp(net.layers{i}.type,'conv'), continue; end
  net.layers{i}.filtersMomentum = zeros(size(net.layers{i}.filters), ...
    class(net.layers{i}.filters)) ;
  net.layers{i}.biasesMomentum = zeros(size(net.layers{i}.biases), ...
    class(net.layers{i}.biases)) ;
  if ~isfield(net.layers{i}, 'filtersLearningRate')
    net.layers{i}.filtersLearningRate = 1 ;
  end
  if ~isfield(net.layers{i}, 'biasesLearningRate')
    net.layers{i}.biasesLearningRate = 1 ;
  end
  if ~isfield(net.layers{i}, 'filtersWeightDecay')
    net.layers{i}.filtersWeightDecay = 1 ;
  end
  if ~isfield(net.layers{i}, 'biasesWeightDecay')
    net.layers{i}.biasesWeightDecay = 1 ;
  end
end

if opts.useGpu
  net = vl_simplenn_move(net, 'gpu') ;
  for i=1:numel(net.layers)
    if ~strcmp(net.layers{i}.type,'conv'), continue; end
    net.layers{i}.filtersMomentum = gpuArray(net.layers{i}.filtersMomentum) ;
    net.layers{i}.biasesMomentum = gpuArray(net.layers{i}.biasesMomentum) ;
  end
end

% -------------------------------------------------------------------------
%                                                        Train and validate
% -------------------------------------------------------------------------

rng(0) ;
report_interval = 50;

if opts.useGpu
  one = gpuArray(single(1)) ;
else
  one = single(1) ;
end

info.train.objective = [] ;
info.train.error = [] ;
info.train.topFiveError = [] ;
info.train.speed = [] ;
info.val.objective = [] ;
info.val.error = [] ;
info.val.topFiveError = [] ;
info.val.speed = [] ;

lr = 0 ;
res = [] ;

for epoch=1:opts.numEpochs
  prevLr = lr ;
  lr = opts.learningRate(min(epoch, numel(opts.learningRate))) ;

  % fast-forward to where we stopped
  modelPath = @(ep) fullfile(opts.expDir, sprintf('net-epoch-%d.mat', ep));
  modelFigPath = fullfile(opts.expDir, 'net-train.png') ;

  if opts.continue
    if exist(modelPath(epoch),'file'), continue ; end
    if epoch > 1
      fprintf('resuming by loading epoch %d\n', epoch-1) ;
      load(modelPath(epoch-1), 'net', 'info') ;
    end
  end

  train = opts.train(randperm(numel(opts.train))) ;
  val = opts.val ;
  test = opts.test ;

  info.train.objective(end+1) = 0 ;
  info.train.error(end+1) = 0 ;
  info.train.topFiveError(end+1) = 0 ;
  info.train.speed(end+1) = 0 ;
  info.val.objective(end+1) = 0 ;
  info.val.error(end+1) = 0 ;
  info.val.topFiveError(end+1) = 0 ;
  info.val.speed(end+1) = 0 ;

  % reset momentum if needed
  if prevLr ~= lr
    fprintf('learning rate changed (%f --> %f): resetting momentum\n', prevLr, lr) ;
    for l=1:numel(net.layers)
      if ~strcmp(net.layers{l}.type, 'conv'), continue ; end
      net.layers{l}.filtersMomentum = 0 * net.layers{l}.filtersMomentum ;
      net.layers{l}.biasesMomentum = 0 * net.layers{l}.biasesMomentum ;
    end
  end

%% evaluation on training data
  for t=1:opts.batchSize:numel(train)
    % get next image batch and labels
    batch = train(t:min(t+opts.batchSize-1, numel(train))) ;
    batch_time = tic ;
    
    if (mod(fix(t/opts.batchSize)+1,report_interval) == 0)
        fprintf('training: epoch %02d: processing batch %3d of %3d ...', epoch, ...
                fix(t/opts.batchSize)+1, ceil(numel(train)/opts.batchSize)) ;
    end
    [im, labels] = getBatch(imdb, batch,1) ;
    
    if opts.prefetch
      nextBatch = train(t+opts.batchSize:min(t+2*opts.batchSize-1, numel(train))) ;
      getBatch(imdb, nextBatch,1) ;
    end
    if opts.useGpu
      im = gpuArray(im) ;
    end

    % backprop
    net.layers{end}.class = labels ;
    res = vl_simplenn(net, im, one, res, ...
      'conserveMemory', opts.conserveMemory, ...
      'sync', opts.sync) ;

    % gradient step
    for l=1:numel(net.layers)
      if ~strcmp(net.layers{l}.type, 'conv'), continue ; end

      net.layers{l}.filtersMomentum = ...
        opts.momentum * net.layers{l}.filtersMomentum ...
          - (lr * net.layers{l}.filtersLearningRate) * ...
          (opts.weightDecay * net.layers{l}.filtersWeightDecay) * net.layers{l}.filters ...
          - (lr * net.layers{l}.filtersLearningRate) / numel(batch) * res(l).dzdw{1} ;

      net.layers{l}.biasesMomentum = ...
        opts.momentum * net.layers{l}.biasesMomentum ...
          - (lr * net.layers{l}.biasesLearningRate) * ....
          (opts.weightDecay * net.layers{l}.biasesWeightDecay) * net.layers{l}.biases ...
          - (lr * net.layers{l}.biasesLearningRate) / numel(batch) * res(l).dzdw{2} ;

      net.layers{l}.filters = net.layers{l}.filters + net.layers{l}.filtersMomentum ;
      net.layers{l}.biases = net.layers{l}.biases + net.layers{l}.biasesMomentum ;
      
      if (mod(fix(t/opts.batchSize)+1,report_interval) == 0)
          r1 = mean(net.layers{l}.filtersMomentum(:)) / mean(net.layers{l}.filters(:));
          r2 = mean(net.layers{l}.biasesMomentum(:)) / mean(net.layers{l}.biases(:));
          if (l == 1) 
              fprintf('\n'); 
          end
          fprintf('layer %d ratio | r1: %f |r2: %f\n', l, r1/report_interval, r2/report_interval);
      end
      
%       mmm = mean(res(l).x(:));
%       fprintf('res mean %d mean %f\n',l, mmm);
      
    end

    % print information
    batch_time = toc(batch_time) ;
    speed = numel(batch)/batch_time ;
    info.train = updateError(opts, info.train, net, res, batch_time) ;
    if (mod(fix(t/opts.batchSize)+1,report_interval) == 0)
        fprintf(' %.2f s (%.1f images/s)', batch_time, speed) ;
        n = t + numel(batch) - 1 ;
        fprintf(' err %.1f err5 %.1f', ...
        info.train.error(end)/n*100, info.train.topFiveError(end)/n*100) ;
        fprintf('\n') ;
    end

    % debug info
    if opts.plotDiagnostics
      figure(2) ; vl_simplenn_diagnose(net,res) ; drawnow ;
    end
  end % next batch

  
  
  
%% evaluation on validation set
    val_prediction_class = zeros(numel(val),1);
  for t=1:opts.batchSize:numel(val)
    batch_time = tic ;
    batch = val(t:min(t+opts.batchSize-1, numel(val))) ;
    
    if (mod(fix(t/opts.batchSize)+1,report_interval) == 0)
        fprintf('validation: epoch %02d: processing batch %3d of %3d ...', epoch, ...
                fix(t/opts.batchSize)+1, ceil(numel(val)/opts.batchSize)) ;
    end
    [im, labels] = getBatch(imdb, batch , 2) ;

    if opts.prefetch
      nextBatch = val(t+opts.batchSize:min(t+2*opts.batchSize-1, numel(val))) ;
      getBatch(imdb, nextBatch,2) ;
    end
    if opts.useGpu
      im = gpuArray(im) ;
    end
   
    net.layers{end}.class = labels;
    res = vl_simplenn(net, im, [], res, ...
      'disableDropout', true, ...
      'conserveMemory', opts.conserveMemory, ...
      'sync', opts.sync) ;

    % print information
    batch_time = toc(batch_time) ;
    speed = numel(batch)/batch_time ;
    
    [info.val, val_prediction_class(t:min(t+opts.batchSize-1, numel(val)))] = updateError(opts, info.val, net, res, batch_time) ;
    if (mod(fix(t/opts.batchSize)+1,report_interval) == 0)
        fprintf(' %.2f s (%.1f images/s)', batch_time, speed) ;
        n = t + numel(batch) - 1 ;
        fprintf(' err %.1f err5 %.1f', ...
        info.val.error(end)/n*100, info.val.topFiveError(end)/n*100) ;
        fprintf('\n') ;
    end      
  end

  
%% evaluation on test set
  test_prediction_class = zeros(numel(test),1);
  for t=1:opts.batchSize:numel(test)
    batch_time = tic ;
    batch = test(t:min(t+opts.batchSize-1, numel(test))) ;
    if (mod(fix(t/opts.batchSize)+1,report_interval) == 0)
        fprintf('test: epoch %02d: processing batch %3d of %3d ...', epoch, ...
            fix(t/opts.batchSize)+1, ceil(numel(test)/opts.batchSize)) ;
    end
    [im] = getBatch(imdb, batch , 3) ;

    if opts.prefetch
      nextBatch = test(t+opts.batchSize:min(t+2*opts.batchSize-1, numel(test))) ;
      getBatch(imdb, nextBatch,3) ;
    end
    if opts.useGpu
      im = gpuArray(im) ;
    end

    net.layers{end}.class = ones(size(batch));
    res = vl_simplenn(net, im, [], res, ...
      'disableDropout', true, ...
      'conserveMemory', opts.conserveMemory, ...
      'sync', opts.sync) ;

    % print information
    batch_time = toc(batch_time) ;
    speed = numel(batch)/batch_time ;
    [test_prediction_class(t:min(t+opts.batchSize-1, numel(test)))] = test_image_prediciton(res) ;
    if (mod(fix(t/opts.batchSize)+1,report_interval) == 0)
        fprintf(' %.2f s (%.1f images/s)', batch_time, speed);
        n = t + numel(batch) - 1 ;
        fprintf('\n') ;
    end
       
  end
  
  
  
%% save
  info.train.objective(end) = info.train.objective(end) / numel(train) ;
  info.train.error(end) = info.train.error(end) / numel(train)  ;
  info.train.topFiveError(end) = info.train.topFiveError(end) / numel(train) ;
  info.train.speed(end) = numel(train) / info.train.speed(end) ;
  info.val.objective(end) = info.val.objective(end) / numel(val) ;
  info.val.error(end) = info.val.error(end) / numel(val) ;
  info.val.topFiveError(end) = info.val.topFiveError(end) / numel(val) ;
  info.val.speed(end) = numel(val) / info.val.speed(end) ;
  info.val.prediction_class = val_prediction_class ;
  info.test.prediction_class = test_prediction_class ;
  
  save(modelPath(epoch), 'net', 'info') ;

  figure(1) ; clf ;
  set(gcf,'position',[1 500 1500 500]);
  set(gcf,'PaperPositionMode','auto');
  subplot(1,2,1) ;
  semilogy(1:epoch, info.train.objective, 'k') ; hold on ;
  semilogy(1:epoch, info.val.objective, 'b') ;
  xlabel('training epoch') ; ylabel('energy') ;
  grid on ;
  h=legend('train', 'val') ;
  set(h,'color','none');
  title('objective') ;
  subplot(1,2,2) ;
  
  switch opts.errorType
    case 'multiclass'
      plot(1:epoch, info.train.error, 'k') ; hold on ;
      plot(1:epoch, info.train.topFiveError, 'k--') ;
      plot(1:epoch, info.val.error, 'b') ;
      plot(1:epoch, info.val.topFiveError, 'b--') ;
      h=legend('train','train-5','val','val-5') ;
    case 'binary'
      plot(1:epoch, info.train.error, 'k') ; hold on ;
      plot(1:epoch, info.val.error, 'b') ;
      h=legend('train','val') ;
  end
  
  grid on ;
  xlabel('training epoch') ; ylabel('error') ;
  set(h,'color','none') ;
  title('error') ;
  drawnow ;

  print(1, modelFigPath, '-dpng') ;
end

%% -------------------------------------------------------------------------
function [info prediction_class] = updateError(opts, info, net, res, speed)
% -------------------------------------------------------------------------
predictions = gather(res(end-1).x) ;
sz = size(predictions) ;
n = prod(sz(1:2)) ;

labels = net.layers{end}.class ;

info.objective(end) = info.objective(end) + sum(double(gather(res(end).x))) ;
info.speed(end) = info.speed(end) + speed ;
switch opts.errorType
  case 'multiclass'

    [~,predictions] = sort(predictions, 3, 'descend') ;
    error = ~bsxfun(@eq, predictions, reshape(labels, 1, 1, 1, [])) ;
    
    info.error(end) = info.error(end) +....
      sum(sum(sum(error(:,:,1,:))))/n ;
    info.topFiveError(end) = info.topFiveError(end) + ...
      sum(sum(sum(min(error(:,:,1:5,:),[],3))))/n ;
    prediction_class = predictions(:,:,1,:);
    prediction_class = reshape(prediction_class,[numel(prediction_class),1]);
    
  case 'binary'
    error = bsxfun(@times, predictions, labels) < 0 ;
    info.error(end) = info.error(end) + sum(error(:))/n ;
    
end

% -------------------------------------------------------------------------
function [prediction_class] = test_image_prediciton(res)
% -------------------------------------------------------------------------
predictions = gather(res(end-1).x) ;
[~,predictions] = sort(predictions, 3, 'descend') ;
prediction_class = predictions(:,:,1,:);
prediction_class = reshape(prediction_class,[numel(prediction_class),1]);

    



