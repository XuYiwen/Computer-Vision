function show_matches(img_R,pos_R,img_S,pos_S,picname)
    two_img = cat(2,img_R,img_S);
    pos_S(1,:) = pos_S(1,:)+ size(img_R,2);
    
    figure(),imshow(two_img),hold on;
    plot(pos_R(1,:),pos_R(2,:),'rx');
    plot(pos_S(1,:),pos_S(2,:),'mx');
    for i = 1: size(pos_R,2)
        x = [pos_R(1,i),pos_S(1,i)];
        y = [pos_R(2,i),pos_S(2,i)];
        plot(x,y,'g-');
    end
    hold off;
    title('feature matches');
        fig = gcf;
        fig.PaperPositionMode = 'auto';
        capture = ['out/', sprintf('%s-matches',picname)];
        print(capture,'-dpng','-r0');
end