sTileDir = "D:\Users\sdammak\Data\LUSC\Tiles\LUSCCancerCells\2000Px_Train_CancerNonCancer_Viable\";
sTargetDir = "D:\Users\sdammak\Data\LUSC\Tiles\MattTrainTiles_2000Px_Viable_Alph2\";
chLabelsPath = "D:\Users\sdammak\Experiments\LUSC-DL\0_3_LBL-001 [2020-12-16_15.08.56]\Results\01 Experiment Section\LBL-001.mat";

% Grab my  images and put them in a directory
% read file that has list of validation tiles
load('D:\Users\sdammak\Data\LUSC\Tiles\LUSCCancerCells\TrainSlides.mat')


if ~exist(sTargetDir, 'dir')
    mkdir(sTargetDir)
    mkdir(sTargetDir + "High")
    mkdir(sTargetDir + "Low")
end

vdChosenSlideCancerContent = nan(1,length(vsTrainSlides));
vsName = strings(length(vsTrainSlides),1);
chAlphabetName = 'A';

% copy tile over to new dir
if isempty(dir(sTargetDir + "*.png"))
    
    vsChosenImagePaths = strings(length(vsTrainSlides), 1);
    % get all the tiles for that image
    for iSlide = 1:length(vsTrainSlides)
        
        stListOfTilesForSlide = dir(sTileDir + vsTrainSlides(iSlide) + "*).png");
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
                        
        sImageFileSource = vsChosenImagePaths(iSlide);
        sLabelFileSource = strrep(vsChosenImagePaths(iSlide),")" , ")-labels");
        
        [vdMuationCount, vbClass, ~] = GetLabelForSlides( vsTrainSlides(iSlide), chLabelsPath);
        
        if vbClass
            sSubfolder = "High\";
        else
            sSubfolder = "Low\";
        end
        
        vsName(iSlide) = string( char(chAlphabetName + iSlide - 1) ) +...
            "_" + num2str(vdMuationCount);
        
        sImageFileTarget = sTargetDir + sSubfolder + vsName(iSlide) + ".png";
        sLabelFileTarget = sTargetDir + sSubfolder + vsName(iSlide) + "-labels.png";
        
        copyfile(sImageFileSource, sImageFileTarget)
        %copyfile(sLabelFileSource, sLabelFileTarget)
    end
    
else
    stChosenImages = dir(sTargetDir + "*).png");
    vsChosenImagePaths = string({stChosenImages.name})';
end

vdChosenSlideCancerPercent = 100 * vdChosenSlideCancerContent./(2000*2000);
tSlidesAndCancerContent = table(vsChosenImagePaths, vdChosenSlideCancerPercent'); 

[vdMuationCount, vbClass, tLabelInfo] = GetLabelForSlides(vsTrainSlides, chLabelsPath);


save(sTargetDir + "\Workspace.mat");
