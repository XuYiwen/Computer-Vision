function show_estimate(pos_S_,pos_S,img_S,picname)
    % find points on epipolar lines L closest to true points
    pos_S_ = pos_S_ ./ repmat(sqrt(pos_S_(:,1).^2 + pos_S_(:,2).^2), 1, 3); % rescale the line
    pt_line_dist = sum(pos_S_ .* pos_S,2);
    closest_pt = pos_S(:,1:2) - pos_S_(:,1:2) .* repmat(pt_line_dist, 1, 2);

    % find endpoints of segment on epipolar line (for display purposes)
    pt1 = closest_pt - [pos_S_(:,2) -pos_S_(:,1)] * 10;
    pt2 = closest_pt + [pos_S_(:,2) -pos_S_(:,1)] * 10;

    % display points and segments of corresponding epipolar lines
    figure(),imshow(img_S); hold on;
    plot(pos_S(:,1), pos_S(:,2), '+r');
    line([pos_S(:,1) closest_pt(:,1)]', [pos_S(:,2) closest_pt(:,2)]', 'Color', 'r');
    line([pt1(:,1) pt2(:,1)]', [pt1(:,2) pt2(:,2)]', 'Color', 'g');
    
    title('Fundamental Fit');
        fig = gcf;
        fig.PaperPositionMode = 'auto';
        capture = ['out/', sprintf('%s-fundafit',picname)];
        print(capture,'-dpng','-r0');
end