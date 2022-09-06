%         function CreateTileCollagesForHighMedLowMutationBins(oTiles, chTargetDir, dLowerMutationBound, dUpperMutationBound)
%             
%             c1chSlideIDs = oTiles.GetPatientIDs();
%             
%             
%         
%         end

dLowerBound = 200;
dUpperBound = 400;
chTargetDir = 'D:\Users\sdammak\Experiments\LUSC_DL\0 Step 3\Collages\[0,200),(400,inf]\with classification separate';

% Example to work with
% load('D:\Users\sdammak\Experiments\LUSC_DL\0 Coded sections\6 TL-009 [2021-07-09_16.55.22]\Results\01 Experiment Section\TL-009_100_min_percent.mat');
% oTiles9 = oTiles;
load('D:\Users\sdammak\Experiments\LUSC_DL\0 Coded sections\6 TL-011 [2021-07-28_11.58.49]\Results\01 Experiment Section\TL-011_100_min_percent.mat');
% oTiles = cat(oTiles9, oTiles);
load('D:\Users\sdammak\Experiments\LUSC_DL\0 Step 3\1121-01-222-1 (013) - Step 3 - train on extremes - 200,400 [2021-07-29_14.24.09]\Results\04 Qualitative classification results\Workspace_in_MATLAB.mat',...
    'c1chUniqueIDs', 'vdConfidenceOfOnePerPatient', 'dPerPatientThreshold')

% Make sure that the input oTilesect doesn't have more than one
% slide per patient
c1chUniquePatientIDs = unique(oTiles.GetPatientIDs());
c1chUniqueSlides = unique(oTiles.GetSampleIDs);
if length(c1chUniquePatientIDs) ~= length(c1chUniqueSlides)
    error("The number of samples per patient is not equal to one in this tile oTilesect. " +...
        "This function requires that.")
end

% vdFirstInstanceOfUniquePatientID: this corresponds
% to the location of the first instance of it in the
% non-unique input vecto
[c1chUniquePatientIDs, vdFirstInstanceOfUniquePatientID, vdLocationOfPatientID]= unique(oTiles.GetPatientIDs);

% Get one tile per unique patient to get one mutation value per
% unique patient
oOneTilePerUniquePatient = oTiles.Select(vdFirstInstanceOfUniquePatientID);

% Check ID matching to make sure the labels are aligned
if any(~strcmp(oOneTilePerUniquePatient.GetPatientIDs(), c1chUniquePatientIDs))
    error("IDs don't match, not sure why, you'll have to examine the code, sorry future me.")
end

% Get the number of unique mutations
c1chUniqueLabels = oOneTilePerUniquePatient.GetLabels();

mkdir([chTargetDir,'\Low']);
mkdir([chTargetDir,'\High']);
mkdir([chTargetDir,'\Med']);

mkdir([chTargetDir,'\Low\TRUE']);
mkdir([chTargetDir,'\High\TRUE']);
mkdir([chTargetDir,'\Med\TRUE']);

mkdir([chTargetDir,'\Low\FALSE']);
mkdir([chTargetDir,'\High\FALSE']);
mkdir([chTargetDir,'\Med\FALSE']);

% Create a collage for each patient
for iPatientIDIdx = 1:length(c1chUniquePatientIDs)
    oCurrentPatientTiles = oTiles.Select(find(vdLocationOfPatientID == iPatientIDIdx));
    chPatientID = c1chUniquePatientIDs{iPatientIDIdx};
    

    
    if ~strcmp(chPatientID, c1chUniquePatientIDs(iPatientIDIdx))
        error("Patient IDs don't match")
    end
        
    dNumMutaions = c1chUniqueLabels(iPatientIDIdx);    
    chSavingsBasePath = [chTargetDir,'\BIN\',num2str(dNumMutaions),' mutations - ',chPatientID];
    
    iIDIdx = contains(c1chUniqueIDs, chPatientID);
    if ~isempty(iIDIdx)
        dPredictedClass = vdConfidenceOfOnePerPatient(iIDIdx) > dPerPatientThreshold;
        dTrueClass = dNumMutaions > 300;
        
        if dTrueClass == 1 && dPredictedClass == 1
            chSavingsBasePath = strrep(chSavingsBasePath, num2str(dNumMutaions), ['TRUE\',num2str(dNumMutaions)]);
        
        elseif dTrueClass == 1 && dPredictedClass == 0
            chSavingsBasePath = strrep(chSavingsBasePath, num2str(dNumMutaions), ['FALSE\',num2str(dNumMutaions)]);
        
        elseif dTrueClass == 0 && dPredictedClass == 0
            chSavingsBasePath = strrep(chSavingsBasePath, num2str(dNumMutaions), ['TRUE\',num2str(dNumMutaions)]);
        
        elseif dTrueClass == 0 && dPredictedClass == 1
            chSavingsBasePath = strrep(chSavingsBasePath, num2str(dNumMutaions), ['FALSE\',num2str(dNumMutaions)]);
        else
            error("Something's squirly. The prediction and/or the truth are not 0 or 1.")
        end
    end
    
    
    if  dNumMutaions < dLowerBound 
        chCurrentSavingsPath = strrep(chSavingsBasePath,'BIN','Low');
    elseif dNumMutaions > dUpperBound
        chCurrentSavingsPath = strrep(chSavingsBasePath,'BIN','High');
    else
        chCurrentSavingsPath = strrep(chSavingsBasePath,'BIN','Med');
    end
    
    Tiles.MakeCollagesOfTiles(oCurrentPatientTiles.GetTilePaths(), 100, chCurrentSavingsPath)
end
