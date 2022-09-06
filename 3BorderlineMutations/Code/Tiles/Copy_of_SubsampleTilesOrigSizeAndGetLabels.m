sTileDir = "D:\Users\sdammak\Data\LUSC\Tiles\LUSCCancerCells\2000Px_Train_CancerNonCancer_Viable\";
sTargetDir = "D:\Users\sdammak\Data\LUSC\Tiles\MattTrainTiles_2000Px_Viable_Alph4\";
chLabelsPath = "D:\Users\sdammak\Experiments\LUSC-DL\0_3_LBL-001 [2020-12-16_15.08.56]\Results\01 Experiment Section\LBL-001.mat";

dNumTilesRequestedPerSlide = 4;

% Grab my  images and put them in a directory
% read file that has list of validation tiles
load('D:\Users\sdammak\Data\LUSC\Tiles\LUSCCancerCells\TrainSlides.mat')


if ~exist(sTargetDir, 'dir')
    mkdir(sTargetDir)
    mkdir(sTargetDir + "High")
    mkdir(sTargetDir + "Low")
end

m2dChosenSlideCancerContent = nan(dNumTilesRequestedPerSlide,length(vsTrainSlides));
m2sTargetName = strings(length(vsTrainSlides),dNumTilesRequestedPerSlide);
chAlphabet = 'A':'Z';

% copy tile over to new dir
if isempty(dir(sTargetDir + "*.png"))
    
    m2sChosenImagePaths = strings(length(vsTrainSlides), dNumTilesRequestedPerSlide);
    iAlph = 1;
    % get all the tiles for that image
    for iSlide = 1:length(vsTrainSlides)
        
        iAlph = iAlph + 1;
        if iAlph > length(chAlphabet)
            iAlph = 1;
        end
        stListOfTilesForSlide = dir(sTileDir + vsTrainSlides(iSlide) + "*).png");
        vdCancerContent = nan(1, length(stListOfTilesForSlide));
        
        % Calculate cancer content for each slide
        for iTile = 1:length(stListOfTilesForSlide)
            
            sChosenTileOrigPath = sTileDir + stListOfTilesForSlide(iTile).name;
            sChosenTileLabelOrigPath = strrep(sChosenTileOrigPath,")" , ")-labels");
            
            m3iMask = imread(sChosenTileLabelOrigPath);
            vdCancerContent(iTile) = sum(sum(sum(m3iMask)));
            
            fclose('all');
        end
        
        % Get dNumTilesRequestedPerSlide tiles that have the highest cancer
        % content
        dNumTilesCopied = 0;
        while dNumTilesCopied ~= dNumTilesRequestedPerSlide
            
            dNumTilesCopied = dNumTilesCopied + 1;
            
            dLargestCancerContentIdx = find(vdCancerContent == max(vdCancerContent));
            
            if length(dLargestCancerContentIdx) > 1
                dLargestCancerContentIdx = dLargestCancerContentIdx(1);
            end
            
            %
            sChosenTileName = string(stListOfTilesForSlide(dLargestCancerContentIdx).name);
            sChosenTileOrigPath = sTileDir + sChosenTileName;
            sChosenTileLabelOrigPath = strrep(m2sChosenImagePaths(iSlide,dNumTilesCopied),")" , ")-labels");
            
            % Get the label and mutation count
            [vdMuationCount, vbClass, ~] = GetLabelForSlides( vsTrainSlides(iSlide), chLabelsPath);
            
            if vbClass
                sSubfolder = "High\";
            else
                sSubfolder = "Low\";
            end
            
            
            sTargetTileName = num2str(vdMuationCount) + "_" + ...
                num2str(iSlide) + ...
                string(repmat(chAlphabet(iAlph), 1, dNumTilesCopied));
            
            sImageFileTarget = sTargetDir + sSubfolder + sTargetTileName + ".png";
            sLabelFileTarget = sTargetDir + sSubfolder + sTargetTileName + "-labels.png";
            
            copyfile(sChosenTileOrigPath, sImageFileTarget)
            %copyfile(sLabelFileSource, sLabelFileTarget)
            
            m2sTargetName(iSlide, dNumTilesCopied) = sTargetTileName;
            m2sChosenImagePaths(iSlide, dNumTilesCopied) = sChosenTileOrigPath;
            m2dChosenSlideCancerContent(iSlide, dNumTilesCopied) = vdCancerContent(dLargestCancerContentIdx);
            
            % Remove the largest so we can get the second largest
            vdCancerContent(dLargestCancerContentIdx) = 0;
            
        end
    end
    
else
    stChosenImages = dir(sTargetDir + "*).png");
    m2sChosenImagePaths = string({stChosenImages.name})';
end

m2dChosenSlideCancerPercent = 100 * m2dChosenSlideCancerContent./(2000*2000);
%tSlidesAndCancerContent = table(vsChosenImagePaths, vdChosenSlideCancerPercent');

[vdMuationCount, vbClass, tLabelInfo] = GetLabelForSlides(vsTrainSlides, chLabelsPath);


save(sTargetDir + "\Workspace.mat");
