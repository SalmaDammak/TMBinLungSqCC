clear

dSideLength = 1108;

dXStartPixel = 49860; %min(tTileDims.XPos);
dXNumImages = 4;
dXEndPixel = dXStartPixel + dXNumImages * dSideLength;
      
dYStartPixel = 35456; %min(tTileDims.YPos);
dYNumImages = 4;
dYEndPixel = dYStartPixel + dYNumImages * dSideLength;

chBaseDir = '\\bainesws01\sdammak\Data\LUSC\Tiles\LUSCCancerCells_7Tiles\1108Px_CancerNonCancer\';
stAllImages = dir([chBaseDir, 'TCGA-21-5787*)-labels.png']);

sPaths = string({stAllImages.name});

for i = 1:length(sPaths)
c1chPlacementInfo =  regexp(sPaths(i),'\((.+)\)','match');
c1chTileInfo = split( c1chPlacementInfo{1}(2:end-1) , ',');

dXTilePosition = str2double(c1chTileInfo{2});
dYTilePosition = str2double(c1chTileInfo{3});

vdTileDims = [dXTilePosition, dYTilePosition];
m2dTileDims(i,:) = vdTileDims;
end

tTileDims = array2table(m2dTileDims, 'VariableNames',{'XPos','YPos'}); 
m2dOutputIm = nan(dYNumImages * dSideLength, dXNumImages * dSideLength, 1);

for dXCurrentPixel = 1: dSideLength : dXNumImages * dSideLength
    
    for dYCurrentPixel = 1 : dSideLength : dYNumImages * dSideLength
        dXCurrentPixelEquivalent = dXCurrentPixel + dXStartPixel - 1;
        dYCurrentPixelEquivalent = dYCurrentPixel + dYStartPixel - 1;
        
        dImRowForXOnly = find(tTileDims.XPos == dXCurrentPixelEquivalent);
        dImRowForYOnly = find(tTileDims.YPos == dYCurrentPixelEquivalent);
                
        dImRow = intersect(dImRowForXOnly, dImRowForYOnly);
        
        if isempty(dImRow)
           error('No corresponding image found!') 
        end
        
        im = imread(string(chBaseDir) + sPaths(dImRow));
        m2dOutputIm(...
                    dYCurrentPixel : dYCurrentPixel + dSideLength - 1,...
                    dXCurrentPixel : dXCurrentPixel + dSideLength - 1, :) = im;
    end
end
% Make pixels in the range [0,1] for showing later
m2dOutputIm = rescale(m2dOutputIm);
imshow(m2dOutputIm, []);

print('D:\Users\sdammak\Data\LUSC\Tiles\Verification images\TCGA-21-5787_CancerNonCancerFromMatlab.png','-dpng')