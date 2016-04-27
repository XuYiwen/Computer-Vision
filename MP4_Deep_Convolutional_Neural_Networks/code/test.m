img = imread('test.jpg');
img = imresize(img,[32,32]);
figure(),
subplot(1,2,1),imshow(img);

% randomly flip image
        if (rand > 0.5)
            img = flip(img,round(rand)+1);
        end
        
        % adding noise
        if(rand > 0)
            img = imnoise(img,'salt & pepper',0.005);
        end
        
        % random cropping image to 28*28
        rand_ori = ceil(rand(1,2).*5);
        rx = rand_ori(1);
        ry = rand_ori(2);
        img = img(rx:rx+27,ry:ry+27,:);
        
        
subplot(1,2,2),imshow(img)        