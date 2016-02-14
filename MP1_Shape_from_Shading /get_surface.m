function  height_map = get_surface(surface_normals, method)
% surface_normals: h*w*3 array of unit surface normals
% image_size: [h, w] of output height map/image  delete
% height_map: height map of object
    
    [h,w,~]=size(surface_normals);
    dx = surface_normals(:,:,1)./surface_normals(:,:,3);
    dy = surface_normals(:,:,2)./surface_normals(:,:,3);
   
    switch method
        case 'column'
            x_init = cumsum(dy(:,1),1);
            x_init = repmat(x_init,[1,w]);
            height_map = x_init + cumsum(dx,2);
            return;
        case 'row'
            cum = cumsum(dx,1);       
            x_init = repmat(cum(:,1),[1,w]);
            height_map = x_init+cumsum(dy,2);
        case 'average'
            dx = repmat(row_init,[h,1])+cumsum(dx,2);
            dy = repmat(col_init,[1,w])+cumsum(dy,1);
            height_map = (dy+dx).*0.5;
        case 'random'
            height_map = zeros(h,w);
            map = zeros(h,w);
            time = 20;
            for t = 1:time; 
                for x = 1:h
                    for y = 1:w
                        sx = x-1; sy = y-1;
                        px = 1; py = 1;
                        h = 0;
                        while(sx>0 || sy>0)
                            dir = rand()>0.5;
                            if(dir && sx > 0)
                                h = h + dy(px,py);
                                sx = sx-1;
                                px = px+1;
                            elseif (~dir && sy > 0)
                                h = h + dx(px,py);
                                sy = sy-1;
                                py = py+1;
                            end 
                        end
                        map(px,py) = h;
                    end
                end
                height_map = height_map +map;
            end
            height_map = height_map./time;
    end

end

