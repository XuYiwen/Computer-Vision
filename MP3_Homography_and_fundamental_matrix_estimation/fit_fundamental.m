function F = fit_fundamental(pos_R,pos_S,normal)
% compute fundamental matrix so that pos_R can be transformed
% into pos_S using pos_S = F* pos_R
    
    N = size(pos_R,1);
    if normal
       % normalize 
       [NR,pos_R] = normalize(pos_R);
       [NS,pos_S] = normalize(pos_S);
    end
        
    % construct linear system
    u = pos_R(:,1);
    v = pos_R(:,2);
    u_ = pos_S(:,1);
    v_ = pos_S(:,2);

    A = [u_.*u, u_.*v, u_, ...
         v_.*u, v_.*v, v_, ...
             u,     v, ones(N,1)];
    
    % get F matrix
    if sum(isinf(A)+isnan(A)) >0
        F = [];
    else
        [~,~,V] = svd(A);
        F=reshape(V(:,9), 3, 3)';
        % enforce rank 2
        [U,D,V] = svd(F);
        F=U*diag([D(1,1) D(2,2) 0])*V';  
    end
    
    if normal
        % denormalize
        F = NS'*F*NR;
    end
end

function [N,npos] = normalize(pos)

    aver = mean(pos,1);
    mx = aver(1); my = aver(2);
    sqrt_d = sqrt((pos(:,1)-mx).^2 + (pos(:,2)-my).^2);
    d = mean(sqrt_d(:));
    s = sqrt(2)/d;
    
    N = [  s,   0, -s*mx; 
           0,   s, -s*my; 
           0,   0,     1];
    npos = (N*pos')';
end