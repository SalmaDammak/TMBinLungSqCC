classdef ClassifiedTiles < LabelledTiles
    
    methods
        function obj = ClassifiedTiles()
            obj = obj@LabelledTiles();
        end
        
        function obj = FillFromDir(obj, chTileDirPath, oLabels, dThreshold)
            obj = FillFromDir@LabelledTiles(obj, chTileDirPath, oLabels);
            
            voClassifiedTiles = ClassifiedTile.empty(0, length(obj.voTiles));
            
            for i = 1 : length(obj.voTiles)
                % (chTileDir, chTileFilename, oLabel, dThreshold)
                oLabel = Label(obj.voTiles(i).chPatientID, obj.voTiles(i).dMutationCount,...
                    obj.voTiles(i).chLabelSourceFile);
                
                voClassifiedTiles(i) = ClassifiedTile(obj.voTiles(i).chTileDir, ...
                    obj.voTiles(i).chTileFilename, oLabel, dThreshold);
            end
            
            obj.voTiles = voClassifiedTiles;
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
                
                % Get the classification for the tiles associated with this ID
                vbClassificationsForCurrentID = vdConfidencesForCurrentID >= NameValueArgs.dThreshold;
                
                % get total number of tiles
                vdTotalNumberOfTiles(dUniqueIDIdx) = sum(vbTileRowsForThisPatient);
                
                % sum labels assigned to tiles
                vdSumOfVotes(dUniqueIDIdx) = sum(vbClassificationsForCurrentID);
                
                % Get the patient vote
                vdConfidenceOfOnePerPatient(dUniqueIDIdx) = vdSumOfVotes(dUniqueIDIdx)/vdTotalNumberOfTiles(dUniqueIDIdx);
                
                % Get the patient truth. Any tile from the patient will do, so we use number 1.
                viTruthsPerPatient = vdTruthPerTile(vbTileRowsForThisPatient); 
                viTruthPerPatient(dUniqueIDIdx) = viTruthsPerPatient(1);
            end
            
        end
        
    end
    
end