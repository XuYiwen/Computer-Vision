function pts_pixel = homo2pixel(pts_homo)
    w = ones(3,1).* pts_homo(3);
    pts_pixel = pts_homo./w;
end