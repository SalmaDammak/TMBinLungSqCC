classdef ClassifiedTiles < LabelledTiles
    
    methods
        function obj = ClassifiedTiles()
            obj = obj@LabelledTiles();
        end
        function obj = FillFromDir(obj, chTileDir, oLabels, dThreshold, NameValueArgs)
            
            arguments
                obj
                chTileDir
                oLabels
                dThreshold
                NameValueArgs.dContinueFromIndex = 1
                NameValueArgs.chPartialFileDirectory = ''
            end
            % Make sure the directory is not empty
            if isempty(dir(chTileDir))
                error("The target directory is empty. Please provide an alternative directory that isn't.")
            end
            
            % Add a '\' if needed
            if ~strcmp(chTileDir(end),'\')
                chTileDir = [chTileDir,'\'];
            end
            
            stTilePaths = dir([chTileDir,'TCGA*].png']);
            
            % Make sure we found with the naming convension we need
            if isempty(stTilePaths)
                error("No files were found matching the regular expression: " +...
                    "'TCGA*].png'. Make sure the directory contains files with " +...
                    "this kind of naming pattern. The directory is:" + newline + chTileDir);
            end
            
            % Clear unused columns because this whole thing takes up a lot
            % of memory
            stTilePaths = rmfield(stTilePaths,{'folder','date','bytes','isdir','datenum'});
            
            % Pre-assign a vector for storage
            c1oClassifiedTiles = cell(length(stTilePaths),1);
            
            % Vector to remove the tiles that will get skipped later
            vbTileSkipped = zeros(length(stTilePaths),1);
            
            % Loop through all tiles in directory
            for iTileIdx = NameValueArgs.dContinueFromIndex:length(stTilePaths)
                
                % Get the filename
                chTileFilename = stTilePaths(iTileIdx).name;
                
                
                    % Get patient ID
                    c1chTilePatientID = regexpi(chTileFilename, TCGAUtilities.chPatientIDExpression, 'match');
                    chTilePatientID = c1chTilePatientID{:};
                    
                    bLabelFound = false;
                    % Find label for patient
                    for iLabelIdx = 1 : length(oLabels.voLabels)
                        
                        chLabelPatientID = oLabels.voLabels(iLabelIdx).chPatientID;
                        
                        if strcmp(chTilePatientID , chLabelPatientID)
                            oLabel = oLabels.voLabels(iLabelIdx);
                            bLabelFound = true;
                            break
                        end
                    end
                    
                    if ~bLabelFound
                        warning(['The label for patient ID: ',chTilePatientID,' was not found,',...
                            ' and therefore this tile was skipped.'])
                        vbTileSkipped(iTileIdx) = 1;
                        continue
                    end
                    
                    % maybe faster
                    %tLabelInfo = ExportToTable(obj, NameValueArgs)
                    
                    % Make into a classified tile  
                try
                    c1oClassifiedTiles{iTileIdx} = ClassifiedTile(chTileDir, chTileFilename, oLabel, dThreshold);                    
                    
                    % Allow tile errors to become warning
                catch oError
                    if strcmp(oError.identifier, "Tile:NonSquareTile")
                        warning("The following tile was not square and therefore skipped: "...
                            + stTilePaths(iTileIdx).name);
                        vbTileSkipped(iTileIdx) = 1;
                        
                    elseif strcmp(oError.identifier, "Tile:TileMaskDoesNotExist")
                        warning("The following tile's mask was not found in the directory and "...
                            +"therefore skipped: " + stTilePaths(iTileIdx).name);
                        vbTileSkipped(iTileIdx) = 1;
                    else                        
                        save('Workspace.mat')                        
                        rethrow(oError);
                    end                    
                end
                
                % Progress tracker
                if (mod(iTileIdx, 1000) == 0) || (iTileIdx == length(stTilePaths))
                    chPerecentDone = string(iTileIdx/length(stTilePaths)*100);
                    disp( chPerecentDone + "% done");
                    
                    % Save partial tile objects if requested by user
                    if ~isempty(NameValueArgs.chPartialFileDirectory)
                        save([NameValueArgs.chPartialFileDirectory,...
                            '\Workspace_PartialTiles_', char(chPerecentDone),'% done.mat'])
                    end
                end                
            end            
            
            % Clean up empty tiles
            c1oClassifiedTiles = c1oClassifiedTiles(find(~vbTileSkipped));
            obj.voTiles = [c1oClassifiedTiles{:}];
            
        end
        
        function obj = FillWithTileObjs(obj, varargin)
            obj = FillWithTileObjs@Tiles(obj, 'ClassifiedTile', varargin);
        end
        
        function vdLabels = GetClasses(obj)
            vdLabels = nan( 1, length(obj.voTiles ) );
            
            for i = 1 : length(obj.voTiles )
                vdLabels(i) = obj.voTiles(i).bClass;
            end
        end
        
        function dPerecentOfClass = GetPercentOfClass(obj, dClassLabel)
            
            dClasses = obj.GetClasses();
            dPerecentOfClass = sum(dClasses == dClassLabel) / length(dClasses);
        end
    end
    methods (Static)
        function obj =  ClassifiedTilesFromLabelledTiles(oLabelledTiles, dThreshold)
            obj = ClassifiedTiles();
            obj.voTiles = ClassifiedTile.empty(0, length(oLabelledTiles));
            for i = 1:length(oLabelledTiles.voTiles)
                obj.voTiles(i) = ClassifiedTile.ClassifiedTileFromLabelledTile(oLabelledTiles.voTiles(i), dThreshold);
            end
            
        end
        
        function [c1chUniqueIDs, vdConfidenceOfOnePerPatient, viTruthPerPatient ,c1vdConfidenceOfOnePerPatient] ...
                = AggregateConfidencesPerPatient(c1chTileFilenames, vdConfidenceOfOnePerTile, vdTruthPerTile, NameValueArgs)
            %[c1chUniqueIDs, vdConfidenceOfOnePerPatient, c1vdConfidenceOfOnePerPatient] ...
            %    = AggregateConfidencesPerPatient(c1chTileFilenames, vdConfidenceOfOnePerTile, 'dThreshold', 0.5)
            %
            % DESCRIPTION:
            %   This function aggregates tile confidences into one
            %   confidence for the patient ID the tiles came from. It does
            %   this by first turning the tile confidences into
            %   classifications, then calculating the fraction of tiles for
            %   that patient that were classified as positive.
            %
            % INPUT ARGUMENTS:
            %  c1chTileFilenames: column vector of tile filenames or filepaths
            %  vdConfidenceOfOnePerTile: column vector containing
            %   the confidence value for each tile
            %   being classified as th epositive class i.e. class 1
            %  dThreshold: confidence equal to or larger than this
            %   confidence threshold lead to the corresponding tile being
            %   classified positive. The default is 0.50, I recommend using
            %   the optimal threshold from the error metrics claculator
            %   (BOLT) or perfcurve (base MATLAB)
            %
            % OUTPUTS ARGUMENTS:
            %  c1chUniqueIDs: column cell array of patient IDs the tiles came from
            %  vdConfidenceOfOnePerPatient: column vector of the overall
            %   confidence of 1 for each unique slide ID
            %  c1vdConfidenceOfOnePerPatient: column cell array of column
            %   vectors containing the confidences from all the tiles
            %   associated with the unique patient ID
            
            % Primary Author: Salma Dammak
            % Last modified: Jun 22, 2022
            
            % The contents of c1chTileFilenames must be charachter strings
            % e.g.
            % 'D:\Users\sdammak\Data\LUSC\Tiles\LUSCCancerCells\227Px_CancerNonCancer\TCGA-21-5787-01Z-00-DX1.FEE037E3-B9B0-4C2E-97EF-D6E4F64E1DF9_(1.00,16798,19295,227,227).png'
            % or
            % 'TCGA-21-5787-01Z-00-DX1.FEE037E3-B9B0-4C2E-97EF-D6E4F64E1DF9_(1.00,16798,19295,227,227).png'
            
            arguments
                c1chTileFilenames (:,1) cell {mustBeText}
                vdConfidenceOfOnePerTile (:,1) double {mustBeNonnegative, mustBeReal, mustBeNonmissing, mustBeFinite, mustBeNonNan}
                vdTruthPerTile (:,1) double {mustBeNonnegative, mustBeReal, mustBeNonmissing, mustBeFinite, mustBeNonNan}
                NameValueArgs.dThreshold (1,1) double {mustBeNonnegative, mustBeReal, mustBeNonmissing, mustBeFinite, mustBeNonNan} = 0.50
                NameValueArgs.bByVoting (1,1) logical = false
                NameValueArgs.bByMean (1,1) logical = false
            end
            
            if NameValueArgs.bByVoting && NameValueArgs.bByMean
                error("Only one method of aggregation is allowed. You cannot set bByMean and bByVoting BOTH to true")
            elseif ~NameValueArgs.bByVoting && ~NameValueArgs.bByMean
                error("At least one method of aggregation is required. You must set either bByMean OR bByVoting to true")
            end
            
            % Get te patient IDs each tile belongs to
            c1chIDForEachTiles = TCGAUtilities.GetPatientIDsFromTileFilepath(c1chTileFilenames);
            
            [c1chUniqueIDs, ~, vdUniqueIDsOriginalLocations] = unique(c1chIDForEachTiles);
            dNumUniqueIDs = length(c1chUniqueIDs);
            
            vdSumOfVotes = nan(dNumUniqueIDs, 1);
            vdTotalNumberOfTiles = nan(dNumUniqueIDs, 1);
            vdConfidenceOfOnePerPatient = nan(dNumUniqueIDs, 1);
            viTruthPerPatient = nan(dNumUniqueIDs, 1);
            c1vdConfidenceOfOnePerPatient = cell(dNumUniqueIDs, 1);
            
            for dUniqueIDIdx = 1:dNumUniqueIDs
                
                % Get the tile rows corresponding to the current patient ID
                vbTileRowsForThisPatient = (vdUniqueIDsOriginalLocations == dUniqueIDIdx);
                
                % Get the confidences of all the tiles associate with this ID
                vdConfidencesForCurrentID = vdConfidenceOfOnePerTile(vbTileRowsForThisPatient);
                c1vdConfidenceOfOnePerPatient{dUniqueIDIdx} = vdConfidencesForCurrentID;
                
                if NameValueArgs.bByVoting
                    % Get the classification for the tiles associated with this ID
                    vbClassificationsForCurrentID = vdConfidencesForCurrentID >= NameValueArgs.dThreshold;
                    
                    % get total number of tiles
                    vdTotalNumberOfTiles(dUniqueIDIdx) = sum(vbTileRowsForThisPatient);
                    
                    % sum labels assigned to tiles
                    vdSumOfVotes(dUniqueIDIdx) = sum(vbClassificationsForCurrentID);
                    
                    % Get the patient vote
                    vdConfidenceOfOnePerPatient(dUniqueIDIdx) = vdSumOfVotes(dUniqueIDIdx)/vdTotalNumberOfTiles(dUniqueIDIdx);
                    
                elseif NameValueArgs.bByMean
                    
                    % Just use the mean of the confidences
                    vdConfidenceOfOnePerPatient(dUniqueIDIdx) = mean(vdConfidencesForCurrentID);
                    
                end
                % Get the patient truth. Any tile from the patient will do, so we use number 1.
                viTruthsPerPatient = vdTruthPerTile(vbTileRowsForThisPatient);
                viTruthPerPatient(dUniqueIDIdx) = viTruthsPerPatient(1);
            end
            
        end
        
    end
    
end