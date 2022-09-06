function [vsChosenFileNames, vsChosenIDs, vsChosenTSS] = GetSubsetOfTCGASlides(dNumRequiredSlides, chDatasetDirectory, vsBlackListedSlidesSVS)
% This function obtains a subset slides from the TCGA LUSC data set using the following rules:
%   1. maximize uniqueness. If dNumSlides < than the number of Tissue Source Sites (TSS),
%      make sure that there are no duplicated TSSs in the output list. If a patient has more than
%      one slide, get a slide from another patient instead.
%   2. in case there are multiple options, choose randomly

% Pre-allocate output containers
vsChosenFileNames = strings(dNumRequiredSlides, 1);
vsChosenIDs = strings(dNumRequiredSlides, 1);
vsChosenTSS = strings(dNumRequiredSlides, 1);

% Get slide info
if ischar(chDatasetDirectory)
[~,vsAllFileNames, vsTSS, vsPatientIDs] = GetSampleSourceInfoForATCGADataset(chDatasetDirectory);

elseif isstring(chDatasetDirectory) % QUICK N DIRTY FIX TO INPUT A VECTOR OF STRINGS OF NAMES INSTEAD OF A DIR
    [~, ~,~, ~,vsPatientIDs, vsTSS] = TCGAUtilities.GetSlideInformationFromSlideNames(chDatasetDirectory);
    vsAllFileNames = chDatasetDirectory;
end

% Remove any blacklisted slides
if ~isempty(vsBlackListedSlidesSVS) 
    bBlackListedSlideIndicesInFullList = false(length(vsAllFileNames), 1);
    
    % Go through every blacklisted slide
    for i = 1:length(vsBlackListedSlidesSVS)
        
        % Make sure it has the right extension
        chSlideName = char(vsBlackListedSlidesSVS(i));
        
        if ~strcmp('.svs',chSlideName(end-3:end)) 
            error("The blacklisted slidenames must end in .svs");            
        end
        
        % Find it in the full list
        dBlackListedSlideIdx = find(strcmp(vsBlackListedSlidesSVS(i), vsAllFileNames));
        
        % Add it to the removal list
        if ~isempty(dBlackListedSlideIdx)
            bBlackListedSlideIndicesInFullList(dBlackListedSlideIdx) = true;
        else
            warning("Slide " + vsBlackListedSlidesSVS(i) + newline + " was not found. "+...
                "It was not used to eliminate any slides from the target directory.")
        end
    end
    
    vsAllFileNames(bBlackListedSlideIndicesInFullList) = [];
    vsTSS(bBlackListedSlideIndicesInFullList) = [];
    vsPatientIDs(bBlackListedSlideIndicesInFullList) = [];
end

% Error if the number of requested slides exceeds what's available
if dNumRequiredSlides > length(vsAllFileNames)
error("GetSubsetOfTCGASlides:BadRequest","The number of slides requested "...
    + "is more than those available. The number of slides requested is " + num2str(dNumRequiredSlides)...
    + ". The number available is " + num2str(length(vsAllFileNames)) + ". " ...
    + "Maybe you blacklisted too many slides.");
end

% Group slides IDs by TSS ID
vsUniqueTSS = unique(vsTSS);
dNumUniqueTSS = length(vsUniqueTSS);

c1vsValidGroupedSlides = cell(dNumUniqueTSS,2);
for k = 1:dNumUniqueTSS
    sUniqueTSS = vsUniqueTSS(k);
    vbIDIndexToGroup = (vsTSS == sUniqueTSS);
    c1vsValidGroupedSlides{k,1} = vsPatientIDs(vbIDIndexToGroup);
    c1vsValidGroupedSlides{k,2} = vsAllFileNames(vbIDIndexToGroup);
end

% Set counters to keep adding until we have the required number
dNumSlidesLeftToGet = dNumRequiredSlides;
dNextEmptyIndex = 1;

while dNumSlidesLeftToGet > 0 
    
    % Use a vector as a counter for the slide picking loop. This vector looks different based on
    % whether have more TSSs than required slides. Also this vector only applies to non-empty sites
    % so we don't get stuck in a loop forever.
    vdNonEmptyTSS = find(~cellfun(@isempty, c1vsValidGroupedSlides(:,1)));
    dNumUniqueNonEmptyTSS = length(vdNonEmptyTSS);
    
    % If the number of slides left to choose is more than or equal to the number of non-empty source 
    % sites, get a slide from every non-empty TSS.
    if dNumSlidesLeftToGet >= dNumUniqueNonEmptyTSS        
        vdTSSsToUse = vdNonEmptyTSS;
    
    % If there are less slides left to get than TSSs pick a subset of them at random
    elseif dNumSlidesLeftToGet < dNumUniqueNonEmptyTSS        
         vdRandomCenterPicker = randperm(dNumUniqueNonEmptyTSS, dNumSlidesLeftToGet);
         vdTSSsToUse = vdNonEmptyTSS(vdRandomCenterPicker);
    end
    
    
    % Pick one from each TSS as specified by our vector, avoiding slides from the same patient if possible
    for i = 1:length(vdTSSsToUse)
        
        dUniqueCenterIdx = vdTSSsToUse(i);
        dNumAvailableAtThisTSS = size(c1vsValidGroupedSlides{dUniqueCenterIdx,1},1);
        
        if ~isempty(c1vsValidGroupedSlides{dUniqueCenterIdx,1}) % This allows for skipping sites that have no samples left
            bSkipThisTSS = false;
            
            % Randomly pick a sample within that TSS and get its corresponding ID
            dIdx = randperm(dNumAvailableAtThisTSS, 1);
            sChosenID = c1vsValidGroupedSlides{dUniqueCenterIdx,1}(dIdx);
            
            % If it's possible to avoid slides from the same patient do so. This is only possible
            % if the number of required slides is less than the number of unique patients.
            if dNumRequiredSlides <= length(unique(vsPatientIDs)) %>"num unique patient IDs"
                    
            % If the site has just one patient and we already have a slide from that patient, 
            % skip this site and empty it to make it invalid
            % if the loop goes through again. This is okay, because we had already checked that
            % we're requesting a number of slides that's less than the unique patient, so what this
            % will do is move the loop to other sites that might have more unique patients.
            if ( length( unique(c1vsValidGroupedSlides{dUniqueCenterIdx,1}) ) <= 1 )...
                && (~isempty(find(vsChosenIDs == sChosenID, 1)))
                % Empty the site
                c1vsValidGroupedSlides{dUniqueCenterIdx,1} = strings(0);
                c1vsValidGroupedSlides{dUniqueCenterIdx,2} = strings(0);
                bSkipThisTSS = true;
            end
            
            
            % Now that we know we have more than one patient at this TSS, keep trying to get
            % a different one if we already have this patient's ID. Delete any discarded IDs to
            % minimize the pool to look in.
            while ~isempty(find(vsChosenIDs == sChosenID, 1))...
                    && (~isempty(c1vsValidGroupedSlides{dUniqueCenterIdx,1}))
                
                % Delete "discarded" IDs and filenames
                c1vsValidGroupedSlides{dUniqueCenterIdx,1}(dIdx) = [];
                c1vsValidGroupedSlides{dUniqueCenterIdx,2}(dIdx) = []; 
                dNumAvailableAtThisTSS = dNumAvailableAtThisTSS -1;
                
                if ~isempty(c1vsValidGroupedSlides{dUniqueCenterIdx,1})
                    dIdx = randperm(dNumAvailableAtThisTSS, 1);
                    sChosenID = c1vsValidGroupedSlides{dUniqueCenterIdx,1}(dIdx);
                else
                    bSkipThisTSS = true;
                end
                
            end            
            end
            
            if ~bSkipThisTSS
            % Add in the chosen slides
            vsChosenIDs(dNextEmptyIndex) = sChosenID;
            vsChosenFileNames(dNextEmptyIndex) = c1vsValidGroupedSlides{dUniqueCenterIdx,2}(dIdx);
            vsChosenTSS (dNextEmptyIndex) = vsUniqueTSS(dUniqueCenterIdx);
            
            % Update the counters
            dNextEmptyIndex = dNextEmptyIndex + 1;
            dNumSlidesLeftToGet = dNumSlidesLeftToGet - 1;
            
            % Delete these IDs from the valid pool
            c1vsValidGroupedSlides{dUniqueCenterIdx,1}(dIdx) = []; % Delete ID that was already used
            c1vsValidGroupedSlides{dUniqueCenterIdx,2}(dIdx) = []; % Delete filename that was already used
            end
            
        end
        
    end
    
end

end


% If the number of requested slides is more than the number of TSSs but less than the unique
% patients, I want to make sure to capture all TSSs, and not get more than one slide for each
% patient. Separate patients from the same source sites into teh same vector, and pick one at a time
% until I have enough.
% if ( dNumRequiredSlides > dNumUniqueTSS ) && ( dNumRequiredSlides < dNumUniquePatientsIDs )
% % If we didn't get one from each TSS, get one from each TSS
%         if dNumChosenSlides <= dNumUniqueTSS
%
%             % Find out how many
%
%             for j = 1:dNumUniqueTSS
%                 dNumAvailableAtThisTSS = length(c1vsGroupedPatientIDs{j});
%
%                 dIdx = randperm(dNumAvailableAtThisTSS, 1);
%
%                 vsChosenIDs = c1vsGroupedPatientIDs{j}(dIdx);
%                 dNumChosenSlides = dNumChosenSlides + 1;
%                 c1vsGroupedPatientIDs{j}(dIdx) = []; % Delete ID that was already used
%             end
%
%         % If we have one from each TSS but we still need more
%         elseif dNumChosenSlides > dNumUniqueTSS
%
% else
%     % Deal with this later if I do actaully ever need it
%     error("Your use cases so far have been satisfying the if condition, you didn't write this branch of code. Sorry.")