classdef TileImagesUtils
    %TileImagesUtils
    %
    % A collection of uttilities to manage the tile images that are output
    % by QuPath onto the drive. This anything from pre-processing their mask,
    % to rearranging the images in a different folder structure.
    
    % Author: Salma Dammak
    % Created: Jun 22, 2022
    
    
    % *********************************************************************   ORDERING: 1 Abstract        X.1 Public       X.X.1 Not Constant
    % *                            PROPERTIES                             *             2 Not Abstract -> X.2 Protected -> X.X.2 Constant
    % *********************************************************************                               X.3 Private
    
    properties (Access = public, Constant = true)
        % Mask REGEXPI string
    end
    
    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static
    % *                          PUBLIC METHODS                           *             2 Not Abstract    X.2 Static
    % *********************************************************************
    
    methods (Access = public, Static = true)
        
        function RemoveTileWithNoMaskInDir(chTileAndMaskDir, NameValueArgs) % TO: update to look for masked images, and remove everything else, likely quicker
            %RemoveTileWithNoMaskInDir(chTileAndMaskDir)
            %
            % DESCRIPTION:
            %   I made this because QuPath 1 would output all the tiles,
            %   with or without a mask, and I needed to remove the tiles
            %   outside the ROI (as inidicated by having a mask) to free up
            %   drive space.
            %
            %   IMPORTANT: this function
            %   Assumes tiles and masks are in the same folder
            %   Does not account for duplicate masks
            %
            % INPUT ARGUMENTS:
            %  chTileAndMaskDir: directory where the masks and tiles were
            %   dumped by QuPath
            %  bQuPath1 : flag to use naming convetion of QuPath 1. Use if
            %   the image was tiled using QuPath 1
            %
            % OUTPUTS ARGUMENTS:
            %  none. The output is a modification of the input directory.
            
            % Author: Salma Dammak
            % Last modified: Jun 22, 2022
            
            arguments
                chTileAndMaskDir (1,:) char {mustBeText,...
                    MyValidationUtils.MustBeExistingDir,...
                    MyValidationUtils.MustBeDirPath,...
                    MyValidationUtils.MustBeNonEmptyDir}
                NameValueArgs.QuPath1 = false
            end
            
            if NameValueArgs.QuPath1
                chLabellingCode = 'labels';
            else
                chLabellingCode = 'labelled';
            end
            
            % Get all tile paths
            stTilePaths = dir([chTileAndMaskDir,'\TCGA-*(*).png']);
            
            % Get all label paths
            stMaskPaths = dir([chTileAndMaskDir,'\TCGA-*(*)-',chLabellingCode,'.png']);
            
            % Go through all tile paths
            for i = 1 : length(stTilePaths)
                
                % Derive the mask path from the tile path
                chCurrentTileName = stTilePaths(i).name;
                chMaskName = strrep(chCurrentTileName, '.png', ['-',chLabellingCode,'.png']);
                
                % If tile path with -labels does not exists in label paths, remove from dir
                % Otherwise, skip it
                if ~any(contains({stMaskPaths(:).name}, chMaskName))
                    delete([stTilePaths(i).folder, '\', stTilePaths(i).name])
                end
            end
        end
        
        function [c1chPathsOfMasksWithBadLabels, c1chSlidesWithBadLabels] = ...
                VerifyMasksForBadLabels(chTileAndMaskDir, vdAcceptableLabels, NameValueArgs)
            %[c1chPathsOfMasksWithBadLabels, c1chSlidesWithBadLabels] = ...
            %   VerifyMasksForBadLabels(chTileAndMaskDir, v1dAcceptableLabels)
            %
            % DESCRIPTION:
            %   This function checks if any masks have values in them that
            %   are outside the list specified by the user.
            %   I made this because I had masks come out with unexpected
            %   label values, which was because the person who did the
            %   contours named the classes in QuPath using a different
            %   spelling for some cases, and QuPath outputs masks for
            %   mismatchign classes with a number not listed in the
            %   extraction scipt. This was in QuPath 1.
            %
            %   IMPORTANT: this function
            %   Assumes tiles and masks are in the same folder
            %   Does not account for duplicate masks
            %
            % INPUT ARGUMENTS:
            %  chTileAndMaskDir: directory where the masks and tiles were
            %   dumped by QuPath
            %  vdAcceptableLabels: a row vector with the label values that
            %   were assigned to classes in the groovy script that was used
            %   to tile the image
            %  bQuPath1 : flag to use naming convetion of QuPath 1. Use if
            %   the image was tiled using QuPath 1
            %
            % OUTPUTS ARGUMENTS:
            %  c1chPathsOfMasksWithBadLabels: a list of masks paths for
            %   inspection
            %  c1chSlidesWithBadLabels: a list of the slides the masks came
            %   from for inspection
            
            % Author: Salma Dammak
            % Last modified: Jun 22, 2022
            
            arguments
                chTileAndMaskDir (1,:) char {mustBeText,...
                    MyValidationUtils.MustBeExistingDir,...
                    MyValidationUtils.MustBeDirPath,...
                    MyValidationUtils.MustBeNonEmptyDir}
                vdAcceptableLabels (1,:) double
                NameValueArgs.QuPath1 = false
            end
            
            if NameValueArgs.QuPath1
                chLabellingCode = 'labels';
            else
                chLabellingCode = 'labelled';
            end
            
            % Get all label paths
            stMaskPaths = dir([chTileAndMaskDir,'TCGA-*-',chLabellingCode,'.png']);
            
            if isempty(stMaskPaths)
                error("The target directory does not have any images with a names following this regular expression: '\TCGA-*-labels.png'.")
            end
            
            c1chPathsOfMasksWithBadLabels = {};
            c1chSlidesWithBadLabels = {};
            dBadMaskListIndex = 1;
            
            for i = 1 : length(stMaskPaths)
                
                chMaskPath = [chTileAndMaskDir, stMaskPaths(i).name];
                try
                    m2iMask = imread(chMaskPath);
                catch oMe
                    disp(oMe)
                end
                viMaskLabels = unique(m2iMask);
                
                if any(~ismember(viMaskLabels,vdAcceptableLabels))
                    c1chPathsOfMasksWithBadLabels{dBadMaskListIndex} = chMaskPath;
                    c1chSlidesWithBadLabels(dBadMaskListIndex) = regexpi(chMaskPath,'(TCGA-\w\w-\w\w\w\w)','match');
                    dBadMaskListIndex = dBadMaskListIndex + 1;
                    warning("A mask with one or more values outside the prespecifed label map indeces was encountered. "+...
                        "The mask path is: " + newline + chMaskPath + newline + "The value(s) encountered: "+...
                        strjoin(string(viMaskLabels(~ismember(viMaskLabels,vdAcceptableLabels)))));
                    
                end
                
            end
            c1chSlidesWithBadLabels = unique(c1chSlidesWithBadLabels);
            close all
            close all hidden
        end
        
        function RemoveTilesWithThisROIClass(chTileAndMaskDir, dClass, NameValueArgs)
            %RemoveTilesWithThisROIClass(chTileAndMaskDir, dClass)
            %RemoveTilesWithThisROIClass(chTileAndMaskDir, dClass,'bRemoveForAnyAmountOfLabel',true)
            %RemoveTilesWithThisROIClass(chTileAndMaskDir, dClass,'bQuPath1', true)
            %
            % DESCRIPTION:
            %   This function removes tiles and masks that have a certain unwanted
            %   label. This is especially useful when wanting to eliminate
            %   masks that have background pixels in them. The function has
            %   two modes of functioning, the default is to remove the
            %   tiles and masks that are entirely from the unwanted ROI
            %   (e.g. fully background). The other way to use it to remove
            %   tiles and masks that have ANY of the unwanted ROI.
            %
            %   IMPORTANT: this function
            %   Assumes tiles and masks are in the same folder
            %   It also does not account for duplicate masks
            %
            % INPUT ARGUMENTS:
            %  chTileAndMaskDir: directory where the masks and tiles were
            %   dumped by QuPath
            %  dClass: the label values that was assigned to the unwanted
            %   classes in the groovy script that was used to tile the image
            %  bRemoveForAnyAmountOfLabel: flag for removing tiles and masks
            %   with any amount of the unwanted label as opposed to being
            %   fully of that label
            %  bQuPath1 : flag to use naming convetion of QuPath 1. Use if
            %   the image was tiled using QuPath 1
           
            % Author: Salma Dammak
            % Last modified: Jul 09, 2022
            arguments
                chTileAndMaskDir (1,:) char {mustBeText,...
                    MyValidationUtils.MustBeExistingDir,...
                    MyValidationUtils.MustBeDirPath,...
                    MyValidationUtils.MustBeNonEmptyDir}
                dClass (1,1) double
                NameValueArgs.bRemoveForAnyAmountOfLabel = false
                NameValueArgs.bQuPath1 = false
            end
            
            if NameValueArgs.bQuPath1
                chLabellingCode = 'labels';
            else
                chLabellingCode = 'labelled';
            end
            
            % Get all label paths
            stMaskPaths = dir([chTileAndMaskDir,'TCGA-*-',chLabellingCode,'.png']);
            
            if isempty(stMaskPaths)
                error(['The target directory does not have any images with a names following this expression: \TCGA-*-',chLabellingCode,'.png.'])
            end
            
            dNumTiles = length(stMaskPaths);
            disp("The original number of tiles is " + num2str(dNumTiles));
            dNumberOftilesRemoved = 0;
            
            % Go through all paths
            for i = 1 : length(stMaskPaths)
                
                % Get the mask and image path
                chMaskPath = [chTileAndMaskDir, stMaskPaths(i).name];
                chTilePath = strrep(chMaskPath,['-',chLabellingCode],'');
                
                % Read the mask and get its unique labels
                m2iMask = imread(chMaskPath);
                viMaskLabels = unique(m2iMask);
                
                if length(viMaskLabels) == 1 ....
                        && viMaskLabels == dClass
                    % Delete the mask and corresponding image if they are
                    % fully that label
                    delete(chMaskPath)
                    delete(chTilePath)
                    dNumberOftilesRemoved = dNumberOftilesRemoved + 1;
                    
                elseif NameValueArgs.bRemoveForAnyAmountOfLabel ...
                        && any(m2iMask(:) == dClass)
                    % Delete mask and its image with ANY of the label
                    delete(chMaskPath)
                    delete(chTilePath)
                    dNumberOftilesRemoved = dNumberOftilesRemoved + 1;
                end
            end
            disp("The number of tiles removed is " + num2str(dNumberOftilesRemoved));
            disp("This is %" + num2str((dNumberOftilesRemoved/dNumTiles)*100)+ " of the original number of tiles.")
        end
        
        function MakeROIClassesIntoForegroundAndBackground(...
                chTileAndMaskDir, vdROIClasses, vbROIClassIsForeground,...
                iForegroundLabel, iBackgroundLabel, NameValueArgs)
            %MakeMultiClassLabelsIntoForegroundAndBackground(chTileAndMaskDir,...
            %   vdROIClassses, vbMaskLabelIsForeground)
            %MakeMultiClassLabelsIntoForegroundAndBackground(chTileAndMaskDir,...
            %   vdROIClassses, vbMaskLabelIsForeground,...
            %   iForegroundLabel, iBackgroundLabel)
            %MakeMultiClassLabelsIntoForegroundAndBackground(chTileAndMaskDir,...
            %   vdROIClasss, vbMaskLabelIsForeground,...
            %   iForegroundLabel, iBackgroundLabel, 'bQuPath1', true)
            % E.g.
            %   MakeMultiClassLabelsIntoForegroundAndBackground('D:\users\sdammak\tiles\',...
            %   [1,2,3,4,5,7], [1,1,1,0,0,0], 1, 0, 'bQuPath1', true)
            %
            % DESCRIPTION:
            %   This function transforms masks with multiple labels into
            %   masks with foreground and background.  
            %
            %   IMPORTANT: this function
            %   Assumes tiles and masks are in the same folder
            %   It also does not account for duplicate masks
            %
            % INPUT ARGUMENTS:
            %  chTileAndMaskDir: directory where the masks and tiles were
            %   dumped by QuPath
            %  vdROIClassses: a row vector with the ROI classes values 
            %   that were assigned to classes in the groovy script that was used
            %   to tile the image
            %  vbMaskLabelIsForeground : a row vector corresponding to the
            %   ROIClasss by position to indicate which are
            %   foreground. 
            %  iForegroundLabel: In the output mask, the forground mask 
            %   classes label becomes this value. Default is 1.
            %  iBackgroundLabel: In the output mask, the background mask 
            %   classes label becomes this value. Default is 0.
            %  bQuPath1: flag to use naming convetion of QuPath 1. Use if
            %   the image was tiled using QuPath 1

            % Author: Salma Dammak
            % Last modified: Jul 09, 2022
            
            arguments
                chTileAndMaskDir (1,:) char {mustBeText,...
                    MyValidationUtils.MustBeExistingDir,...
                    MyValidationUtils.MustBeDirPath,...
                    MyValidationUtils.MustBeNonEmptyDir}
                vdROIClasses (1,:) double
                vbROIClassIsForeground (1,:) logical 
                iForegroundLabel (1,1) int32 = int32(1)
                iBackgroundLabel (1,1) int32 = int32(0)
                NameValueArgs.bQuPath1 = false
            end
            
            if length(vdROIClasses) ~= length(vbROIClassIsForeground)
                error('The length of the mask labels vector must equal that of the vector indicating which are foreground.')
            end
            
            if NameValueArgs.bQuPath1
                chLabellingCode = 'labels';
            else
                chLabellingCode = 'labelled';
            end
            
            % Get all label paths
            stMaskPaths = dir([chTileAndMaskDir,'TCGA-*-',chLabellingCode,'.png']);
            
            if isempty(stMaskPaths)
                error(['The target directory does not have any images with a names following this expression: \TCGA-*-',chLabellingCode,'.png.'])
            end            
            
            % Loop through all the masks
            for i = 1 : length(stMaskPaths)
                                
                % Track progress
                dPercentDone = (i*100)/length(stMaskPaths);
                
                if rem(dPercentDone,1) == 0
                    disp(string(dPercentDone) + "% done!");
                end
                
                % Read the mask and get its class labels
                chFullMaskPath = [chTileAndMaskDir, stMaskPaths(i).name];                
                m2iMask = imread(chFullMaskPath);                
                viCurrentMaskLabels = unique(m2iMask);
                
                % Verify that the mask does not contain any values outside
                % the vdROIClasses provided. A value not within the
                % list could mean an error in classifying or an error in 
                % the class names in the extraction code. Either way, this
                % code can't handle it because it doesn't know whether it
                % shoudl be background or foreground.
                if any(~ismember(viCurrentMaskLabels,vdROIClasses))
                    error("A mask with one or more values outside the prespecifed label map indeces was encountered. "+...
                        "The mask path is: " + newline + chFullMaskPath + newline + "The value(s) encountered: "+...
                        viCurrentMaskLabels(~ismember(viCurrentMaskLabels,vdROIClasses)));                    
                else
                
                    % Create a new mask to over-write the original
                    m2iNewMask = m2iMask;
                    
                    % Loop through the list of class labels the user
                    % provided and trnsform them in the new mask to their
                    % new values
                    for iLabel = 1:length(vdROIClasses)
                        % If the label is foreground give it foreground label, 
                        % otherwise make give it the background label
                        if vbROIClassIsForeground(iLabel)
                            m2iNewMask(m2iMask == vdROIClasses(iLabel)) = iForegroundLabel;
                       
                        elseif ~vbROIClassIsForeground(iLabel)
                            m2iNewMask(m2iMask == vdROIClasses(iLabel)) = iBackgroundLabel;
                        
                        else
                            error("vbMaskLabelIsForeground is not set a value of true or false. "...
                                + newline + "Image: " + string(chFullMaskPath) + newline + "Value: " +...
                                string(vbROIClassIsForeground(iLabel)) + ".")
                        end
                    end
                    
                    % Over-write mask
                    imwrite(m2iNewMask, chFullMaskPath)
                end
            end
        end
        
    end
end

