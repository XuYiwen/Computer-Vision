function  height_map = get_surface(surface_normals, method)
% surface_normals: h*w*3 array of unit surface normals
% image_size: [h, w] of output height map/image  delete
% height_map: height map of object
    
    [h,w,~]=size(surface_normals);
    dc = surface_normals(:,:,1)./surface_normals(:,:,3);
    dr = surface_normals(:,:,2)./surface_normals(:,:,3);
   
    switch method
        case 'column'
            c_init = cumsum(dr(:,1),1);
            c_init = repmat(c_init,[1,w]);
            dc(:,1) = zeros(h,1);
            height_map = c_init + cumsum(dc,2);
            return;
        case 'row'
            r_init = cumsum(dc(1,:),2);
            r_init = repmat(r_init,[h,1]);
            dr(1,:) = zeros(1,w);
            height_map = r_init + cumsum(dr,1);
            return;
        case 'average'
            c_init = cumsum(dr(:,1),1);
            c_init = repmat(c_init,[1,w]);
            dc(:,1) = zeros(h,1);
            
            r_init = cumsum(dc(1,:),2);
            r_init = repmat(r_init,[h,1]);
            dr(1,:) = zeros(1,w);
            
            height_map = r_init + cumsum(dr,1);
            height_map = height_map + c_init + cumsum(dc,2);
            height_map = height_map.*0.5;
            return;
        case 'random'
            height_map = zeros(h,w);
            map = zeros(h,w);
            time = 10;
            for t = 1:time; 
                for r = 1:h
                    for c = 1:w
                        sr = r-1; sc = c-1;
                        pr = 1; pc = 1;
                        h = 0;
                        while(sr>0 || sc>0)
                            dir = rand()>0.5;
                            if(dir && sr > 0)
                                pr = pr+1;
                                sr = sr-1;
                                h = h + dr(pr,pc);                                
                            elseif (~dir && sc > 0)
                                pc = pc+1;
                                sc = sc-1;
                                h = h + dc(pr,pc);
                            end 
                        end
                        map(pr,pc) = h;
                    end
                end
                height_map = height_map +map;
            end
            height_map = height_map./time;
            return;
        case 'onedim-random'
            times = 20;
            height_map = zeros(h,w);
            for t = 1:times
                rand_r = ceil(rand()*h);
                r_init = cumsum(dc(rand_r,:),2);
                r_init = repmat(r_init,[h,1]);

                up = dr(1:rand_r-1,:);
                cum_up = cumsum(-up,1,'reverse');
                down = dr(rand_r+1:end,:);
                cum_down = cumsum(down,1);
                cum = [cum_up;zeros(1,w);cum_down];
                height_map = height_map+r_init + cum;
            end
            height_map = height_map./times;
            return;
    end

end

