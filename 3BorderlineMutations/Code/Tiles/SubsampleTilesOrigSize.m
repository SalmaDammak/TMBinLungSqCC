sTileDir = "D:\Users\sdammak\Data\LUSC\Tiles\LUSCCancerCells\2000Px_Val_CancerNonCancer_Viable\";
sTargetDir = "D:\Users\sdammak\Data\LUSC\Tiles\MattTestTiles_2000Px_Viable_Alph\";


% Grab my  images and put them in a directory
% read file that has list of validation tiles
load('D:\Users\sdammak\Data\LUSC\Tiles\LUSCCancerCells\ValidationTiles.mat')


if ~exist(sTargetDir, 'dir')
    mkdir(sTargetDir)
end

vdChosenSlideCancerContent = nan(1,length(vsValidationTiles));
vsName = strings(length(vsValidationTiles),1);
chAlphabetName = 'A';

% copy tile over to new dir
if isempty(dir(sTargetDir + "*.png"))
    
    vsChosenImagePaths = strings(length(vsValidationTiles), 1);
    % get all the tiles for that image
    for iSlide = 1:length(vsValidationTiles)
        
        stListOfTilesForSlide = dir(sTileDir + vsValidationTiles(iSlide) + "*).png");
        vdCancerContent = nan(1, length(stListOfTilesForSlide));
        
        % allows for breaking out as soon as a 100% cancer tile is found
        bFound = false;
        
        for j = 1:length(stListOfTilesForSlide)
            
            sImageFileSource = sTileDir + stListOfTilesForSlide(j).name;
            sLabelFileSource = strrep(sImageFileSource,")" , ")-labels");            
            
            m3iMask = imread(sLabelFileSource);
            vdCancerContent(j) = sum(sum(sum(m3iMask)));
            
            if vdCancerContent(j)/numel(m3iMask) == 1
                bFound = true;
                break
            end
            
            fclose('all');
        end
        
        if bFound
            dLargestCancerContentIdx = j;
        else
            dLargestCancerContentIdx = find(vdCancerContent == max(vdCancerContent));
        end
        
        if length(dLargestCancerContentIdx) > 1
            dLargestCancerContentIdx = dLargestCancerContentIdx(1);
        end
        
        sChosenSlideName = string(stListOfTilesForSlide(dLargestCancerContentIdx).name);
        vsChosenImagePaths(iSlide) = sTileDir + sChosenSlideName;
        vdChosenSlideCancerContent(iSlide) = vdCancerContent(dLargestCancerContentIdx);
        
        %chChosenImagePaths = char(vsChosenImagePaths(iSlide));
        %vsName(iSlide) = string(chChosenImagePaths(84 : 84+11));
        vsName(iSlide) = string( char(chAlphabetName + iSlide - 1) );
        
        sImageFileSource = vsChosenImagePaths(iSlide);
        sLabelFileSource = strrep(vsChosenImagePaths(iSlide),")" , ")-labels");
        
        sImageFileTarget = sTargetDir + vsName(iSlide) + ".png";
        sLabelFileTarget = sTargetDir + vsName(iSlide) + "-labels.png";
        
        copyfile(sImageFileSource, sImageFileTarget)
        copyfile(sLabelFileSource, sLabelFileTarget)
    end
    
else
    stChosenImages = dir(sTargetDir + "*).png");
    vsChosenImagePaths = string({stChosenImages.name})';
end

vdChosenSlideCancerPercent = 100 * vdChosenSlideCancerContent./(2000*2000);
tSlidesAndCancerContent = table(vsChosenImagePaths, vdChosenSlideCancerPercent'); 
save(sTargetDir + "\Workspace.mat");

run('GetClassForSlide.m')