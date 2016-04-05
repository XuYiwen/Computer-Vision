function [aver_dist,dist] = check_fundamental(pos_S_,pos_S,display)
    % find points on epipolar lines L closest to true points
    pos_S_ = pos_S_ ./ repmat(sqrt(pos_S_(:,1).^2 + pos_S_(:,2).^2), 1, 3); % rescale the line
    pt_line_dist = sum(pos_S_ .* pos_S,2);
    closest_pt = pos_S(:,1:2) - pos_S_(:,1:2) .* repmat(pt_line_dist, 1, 2);
    
    % report mean squared distance
    dist = sqrt((closest_pt(:,1)-pos_S(:,1)).^2 + (closest_pt(:,2)-pos_S(:,2)).^2);
    aver_dist = mean(dist);
    
    if display
        fprintf('Mean Squared Distance: %.2f\n', aver_dist);
    end
end