clear 
close all

chImPath = 'D:\Users\sdammak\Data\LUSC\Original\Histology\TCGA-6A-AB49-01Z-00-DX1.FDF2EED7-57A3-4019-A382-21DED11780F6.svs';
dXLocationOnOriginalImage = 0;
gridSpacing = 10000;
subgridSpacing = 5000;



% Get the image info
info=imfinfo(chImPath);

% Show low-res image (original:level5 is 1:32)
level = 5;
reductionFactor = 2^level;
rgb=imread(chImPath,'Index',level);
imshow(rgb)
hold on

adjustedGridSpacing = round(gridSpacing/reductionFactor);
adjustedSubGridSpacing = round(subgridSpacing/reductionFactor);

M = size(rgb,1);
N = size(rgb,2);

for k = 1:adjustedGridSpacing:M
    x = [1 N];
    y = [k k];
%     plot(x,y,'Color','g','LineStyle','-');
    plot(x,y,'Color','k','LineStyle','-');
end

for k = 1:adjustedGridSpacing:N
    x = [k k];
    y = [1 M];
    %plot(x,y,'Color','g','LineStyle','-');
    plot(x,y,'Color','k','LineStyle','-');
end

for k = 1:adjustedSubGridSpacing:M
    x = [1 N];
    y = [k k];
    plot(x,y,'Color','k','LineStyle',':');
end

for k = 1:adjustedSubGridSpacing:N
    x = [k k];
    y = [1 M];
    plot(x,y,'Color','k','LineStyle',':');
end
hold off