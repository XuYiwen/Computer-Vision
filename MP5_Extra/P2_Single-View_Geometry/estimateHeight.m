function object_h = estimateHeight(img, ground_line, vp_z,  obj,refer_h)
    figure(4), hold off, imagesc(img);

    % get user input
    fprintf('>>> get top and buttom of human\n');
        [x,y] = ginput(2);
        r_top = [x(1) ; y(1);1];
        r_base = [x(2); y(2);1];

    fprintf('>>> get top and buttom of %s\n', obj);
        [x,y] = ginput(2);
        o_top = [x(1) ; y(1);1];
        o_base = [x(2); y(2);1];

    % compute height
    button_line = real( cross(r_base ,o_base));
    v0 = real( cross( button_line, ground_line)); v0 = homo2pixel(v0);
    top_line = real(cross(v0, r_top));
    obj_line = real(cross(o_top, o_base));
    
    T = real(cross(top_line,obj_line)); T = homo2pixel(T);
    B = o_base;
    R = o_top;
    
    object_h = refer_h * norm(R - B) * norm(vp_z - T) / norm(T - B) / norm(vp_z - R);
    
    %% display 
    hold on
    pts = [r_top, r_base, o_top, o_base, v0];
    lines = [ground_line, button_line, top_line, obj_line];
    
    % show lines
    bx1 = min([pts(1,:), 1])-10; bx2 = max([pts(1,:), size(img,2)])+10;
    by1 = min([pts(2,:), 1])-10; by2 = max([pts(2,:), size(img,1)])+10;
    for k = 1:size(lines, 2)
        if lines(1,k)<lines(2,k)
            pt1 = real(cross([1 0 -bx1]', lines(:, k)));
            pt2 = real(cross([1 0 -bx2]', lines(:, k)));
        else
            pt1 = real(cross([0 1 -by1]', lines(:, k)));
            pt2 = real(cross([0 1 -by2]', lines(:, k)));
        end
        pt1 = pt1/pt1(3);
        pt2 = pt2/pt2(3);
        plot([pt1(1) pt2(1)], [pt1(2) pt2(2)], 'g', 'Linewidth', 1);
    end
    
    % show points
    for k = 1: size(pts,2)
        hold on, plot(pts(1,:), pts(2,:),'*r');
    end
    
    axis image
    axis([bx1 bx2 by1 by2]); 
    title(sprintf('Height Estimate for %s = %.1f', obj, object_h));
        set(gcf,'PaperPositionMode','auto');
        print(4, sprintf('height_%s_%1.0f.png',obj,floor(refer_h)), '-dpng') ;
end
