function A = cross_product_matrix(a,b)
    ax = a(1); ay = a(2); az = a(3);
    
    Ac = [  0, -az,  ay;
           az,   0, -ax;
          -ay,  ax,   0];
    A = Ac*b;
end