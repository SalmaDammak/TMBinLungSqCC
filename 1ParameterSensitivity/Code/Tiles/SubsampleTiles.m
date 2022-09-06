sLabelDir = "D:\Users\sdammak\Data\LUSC\Tiles\LUSCCancerCells\10000Px_Val_CancerNonCancer\";
sTileDir = "D:\Users\sdammak\Data\LUSC\Tiles\LUSCCancerCells\10000Px_Val_CancerNonCancer\";
sTargetDir = "D:\Users\sdammak\Data\LUSC\Tiles\MattTestTiles_10000Px";
sFinalTargetDir = "D:\Users\sdammak\Data\LUSC\Tiles\MattTestTiles_227Px\";
dOutputSideLength = 500;

% Grab my 1108 x 1008 images and put them in a directory
% read file that has list of validation tiles
%load('D:\Users\sdammak\Data\LUSC\Tiles\LUSCCancerCells\ValidationTiles.mat')
load('\\bainesws01\sdammak\Data\LUSC\Tiles\LUSCCancerCells\ValidationTiles.mat')



if ~exist(sTargetDir, 'dir')
    mkdir(sTargetDir)
end


% copy tile over to new dir
if isempty(dir(sTargetDir + "\*.png"))
    
    vsChosenImagePaths = strings(length(vsValidationTiles), 1);
    % get all the tiles for that image
    for iSlide = 1:length(vsValidationTiles)
        
        stListOfTilesForSlide = dir(sTileDir + vsValidationTiles(iSlide) + "*).png");
        vdCancerContent = nan(1, length(stListOfTilesForSlide));
        
        for j = 1:length(stListOfTilesForSlide)
            sImageFile = sTileDir + stListOfTilesForSlide(j).name;
            
            sLabelFile = strrep(sImageFile, sTileDir, sLabelDir);
            sLabelFile = strrep(sLabelFile,")" , ")-labels");
            
            
            m3iMask = imread(sLabelFile);
            vdCancerContent(j) = sum(sum(sum(m3iMask)));
            
            fclose('all');
        end
        
        dLargestCancerContentIdx = find(vdCancerContent == max(vdCancerContent));
        
        if length(dLargestCancerContentIdx) > 1
            dLargestCancerContentIdx = dLargestCancerContentIdx(1);
        end
        
        sChosenSlideName = string(stListOfTilesForSlide(dLargestCancerContentIdx).name);
        vsChosenImagePaths(iSlide) = sTileDir + sChosenSlideName;
    end
    for i = 1:length(vsChosenImagePaths)
        
        sImageFile = vsChosenImagePaths(i);
        sLabelFile = strrep(vsChosenImagePaths(i),")" , ")-labels");
        
        copyfile(sImageFile, sTargetDir)
        copyfile(sLabelFile, sTargetDir)
    end
    
else
    stChosenImages = dir(sTargetDir + "\*).png");
    vsChosenImagePaths = string({stChosenImages.name})';
end

if ~exist(sFinalTargetDir, 'dir')
    mkdir(sFinalTargetDir)
end

vdCancerContent = nan(length(vsChosenImagePaths),1);
for k = 1:length(vsChosenImagePaths)
    
    sImageFile = sTileDir + vsChosenImagePaths(k);
    sLabelFile = strrep(sImageFile, sTileDir, sLabelDir);
    sLabelFile = strrep(sLabelFile,")" , ")-labels");
    
    
    m3iOrigImage = imread(sImageFile);
    m3iMask = imread(sLabelFile);
    
    dImageInContour = false;
    
    
    dNumCols = floor(size(m3iOrigImage,2) / dOutputSideLength);
    dNumRows = floor(size(m3iOrigImage,1) / dOutputSideLength);
    
    m2dCancerInMask = nan(dNumRows, dNumCols);
    m2dXOrigin = nan(dNumCols,1);
    m2dYOrigin = nan(dNumRows,1);
    
    % Travel along the y axis
    for dRow = 1:dNumRows
        
        dYOrigin = dOutputSideLength * dRow - dOutputSideLength;
        m2dYOrigin(dRow) = dYOrigin;
        
        % Travel along the x axis
        for dCol = 1:dNumCols
            
            dXOrigin = dOutputSideLength * dCol - dOutputSideLength;
            m3iCroppedMask = imcrop(m3iMask, [dXOrigin, dYOrigin, dOutputSideLength, dOutputSideLength]);
            m2dXOrigin(dCol) = dXOrigin;
            
            m2dCancerInMask(dRow, dCol) = sum(sum(m3iCroppedMask));
        end
    end
    
    dMaxCancer = max(max(m2dCancerInMask));
    if length(dMaxCancer) > 1
        dMaxCancer = dMaxCancer(1);
    end
    
    vdCancerContent(k) = dMaxCancer;
    
    [dMostCancerX, dMostCancerY] = find(m2dCancerInMask == dMaxCancer);
    
    if length(dMostCancerX) > 1
        dMostCancerX = dMostCancerX(randperm(length(dMostCancerX),1));
    end
    
    if length(dMostCancerY) > 1
        dMostCancerY = dMostCancerY(randperm(length(dMostCancerY),1));
    end
    
    m3iCroppedImage = imcrop(m3iOrigImage, ...
        [m2dXOrigin(dMostCancerX), ...
        m2dYOrigin(dMostCancerY), ...
        (dOutputSideLength -1), (dOutputSideLength -1)]);
    
    sTargetImPath = strrep(sImageFile, sTileDir, sFinalTargetDir);
    imwrite(m3iCroppedImage, sTargetImPath);
    
    fclose('all');
end
