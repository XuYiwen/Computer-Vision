function vec = normalize_line(vec)
    k = sqrt(vec(1)^2+ vec(2)^2);
    vec = vec./k;
end