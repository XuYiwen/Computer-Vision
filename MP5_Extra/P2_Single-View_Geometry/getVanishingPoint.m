function vp = getVanishingPoint(im)
% output vanishing point, input image

figure(1), hold off, imagesc(im)
hold on 

% Allow user to input line segments; compute centers, directions, lengths
disp('Set at least two lines for vanishing point')
lines = zeros(3, 0);
line_length = zeros(1,0);
centers = zeros(3, 0);
while 1
    disp(' ')
    disp('Click first point or q to stop')
    [x1,y1,b] = ginput(1);    
    if b=='q'        
        break;
    end
    disp('Click second point');
    [x2,y2] = ginput(1);
    plot([x1 x2], [y1 y2], 'b')
    lines(:, end+1) = real(cross([x1 y1 1]', [x2 y2 1]'));
    line_length(end+1) = sqrt((y2-y1)^2 + (x2-x1).^2);
    centers(:, end+1) = [x1+x2 y1+y2 2]/2;
end

%% solve for vanishing point 
N = size(lines,2);
% ignore short lines
del = find(line_length <= 20);
lines(:,del) = [];
line_length(del) = [];
centers(:,del) = [];

% find all vanishing point candidates
vp_set = [];
sc_set = [];
for i = 1:N
    for j = i+1:N
        la = lines(:,i);
        lb = lines(:,j);
        
        vp_c = cross(la,lb);
        vp_set(end+1) = vp_c;
    end
end

% compute
% vp candidates to center of line
        vp_line = cross(vp_c,center)
        
        % compute score for point candidates
        theta = atan2(-la(1),la(2));
        alpha = atan2(-l)

vp_all = zeros(3,N);
for i = 1:N
    vp_all(:,i) = cross(lines(:,(i-1)*2+1),lines(:,(i-1)*2+2));
end 
vp = vp_all();

%% display 
hold on
bx1 = min(1, vp(1)/vp(3))-10; bx2 = max(size(im,2), vp(1)/vp(3))+10;
by1 = min(1, vp(2)/vp(3))-10; by2 = max(size(im,1), vp(2)/vp(3))+10;
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
plot(vp(1)/vp(3), vp(2)/vp(3), '*r')
axis image
axis([bx1 bx2 by1 by2]); 

