% function [img_space,scl_space] = DoG(img,sigma,maxR,s)
%     [h,w] = size(img); 
%     
%     % Calculate numbers of octave
%     num_oct = 0;
%     ini_sig = sigma;
%     while (maxR/sqrt(2) > ini_sig*(2^num_oct)) 
%         num_oct = num_oct+1;   
%     end
%         
%     img_space = zeros(h,w,num_oct*s);
%     scl_space = zeros(num_oct*s,1);scl_space(1) = ini_sig;
%     
%     t_start = tic;
%     
%     % intialization
%     subh = h; subw = w;
%     gau_sig = fspecial('gaussian',ini_sig*6,ini_sig);
%     ini_img = imfilter(img,gau_sig,'symmetric');   
%     k = nthroot(2,s)
%     gau_k = fspecial('gaussian',ceil(k*6),k);  
%     
%     for i = 1:num_oct
%         % initial gaussian image stack
%         gimg_stack = zeros(subh, subw, s+1);
%         gimg_stack(:,:,1) = ini_img;
%         
%         for j = 1:s
%             % compute upper layer of guassian-ed image
%             last = gimg_stack(:,:,j);
%             next = imfilter(last,gau_k,'symmetric');
%             gimg_stack(:,:,j+1) = next;
%             
%             % substract and put into DoG stack
%             DoG = next - last;
%             DoG = imresize(DoG,[h,w],'bicubic');
%             img_space(:,:,i) = DoG;
%             scl_space(:,:,i) = ini_sig * k^(j-1);
%         end
%         
%         % update new ini_sig and ini_img
%         subh = ceil(h/(2^i));
%         subw = ceil(w/(2^i));
%         ini_img = imresize(gimg_stack(:,:,end),[subh,subw]);
%         ini_img = imfilter(ini_img,gau_sig,'symmetric');  
%     end
%     t = toc(t_start);
%     fprintf('Running Time - DoG: %6.6f s\n',t);
%     
%     scl_space = scl_space(1:end,1).*sqrt(2);
% end

% function [dogpyr,sclpyr] = DoG(img,ini_sig,maxR,nOctLayers)
%     [h,w] = size(img); 
%     
%     % Calculate numbers of octave
%     num_oct = 0;
%     while (maxR/sqrt(2) > ini_sig*(2^num_oct)) 
%         num_oct = num_oct+1;   
%     end
%     num_oct = num_oct-1;
%     k = nthroot(2,nOctLayers);
%     
%     % Precompute guassian filter in octave
%     sigpyr = zeros(nOctLayers+3,1);
%     sigpyr(1) = ini_sig;
%     gau_set{1} = fspecial('gaussian',ini_sig*6,ini_sig);
%     for i = 2:(nOctLayers+3)
%         sig_prev = ini_sig * k^(i-2);
%         sig_total = sig_prev * k;
%         sigpyr(i) = sqrt(sig_total*sig_total-sig_prev*sig_prev);
%         gau_set{i} = fspecial('gaussian',ceil(sigpyr(i)*6),sigpyr(i));
%     end
%     
%     dogpyr = zeros(h,w,num_oct*(nOctLayers+2));
%     sclpyr = zeros(num_oct*(nOctLayers+2),1);
%     subh = h; subw = w;
%     gau_octave = zeros(subh,subw,nOctLayers+3);
%     gau_octave(:,:,1) = imfilter(img,gau_set{1},'symmetric');
%     for o = 1:num_oct
%         for l = 2:nOctLayers+3
%             % get next Gaussian level
%             gau_octave(:,:,l) = imfilter(gau_octave(:,:,l-1),gau_set{l},'symmetric');
%             diff= gau_octave(:,:,l)- gau_octave(:,:,l-1);
%             dogpyr(:,:,(o-1)*num_oct+l-1) = imresize(diff,[h,w],'bicubic');
%             sclpyr((o-1)*num_oct+l-1) = sigpyr(i);
%         end
%         top = gau_octave(:,:,nOctLayers+1);
%         subh = ceil(subh/2);
%         subw = ceil(subw/2);
%         gau_octave = zeros(subh,subw,nOctLayers+3);
%         gau_octave(:,:,1) = imresize(top,[subh,subw]);
%     end
%     sclpyr = sclpyr.*sqrt(2);