classdef Tiles
    properties (SetAccess = protected)
        voTiles
    end
    properties (Access = public, Constant = true)
        m2dQuPathMap =...
            [255 ,255 , 255;...% 0 - white > "background"
            23   ,137 ,187;... % 1 - teal > "central"
            200  ,255 ,200;... % 2 - pale green > "peripheral"
            90   ,69  ,40; ... % 3 - brown > "central,  non-viable"
            25   ,94  ,131;... % 4 - dark blue > "central, viable"
            153  ,51  ,255; ... % 5 - medium purple > "peripheral, non-viable"
            204  ,204 ,255;  ... % 6 - light purple  > "peripheral,  viable"
            75   ,0   ,205]/255;% 7 - dark and blueish purple> "non-tumour non-cancer"
    end
    
    methods
        % Constructor
        function obj = Tiles()
            obj.voTiles = [];
        end
        
        function obj = FillFromDir(obj, chTileDir)
            arguments
                obj
                chTileDir (1,:) char
            end
            
            % 1 - Get tiles from directory mode
            
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
            
            stTilePaths = rmfield(stTilePaths,{'folder','date','bytes','isdir','datenum'});
            obj.voTiles  = [];
            for i = 1 : length(stTilePaths)
                
                try
                    obj.voTiles = [obj.voTiles, Tile(chTileDir, stTilePaths(i).name)];
                    
                catch oErrorFromTileClass
                    
                    if strcmp(oErrorFromTileClass.identifier, "Tile:NonSquareTile")
                        warning("The following tile was not square and therefore skipped: "...
                            + stTilePaths(i).name);
                        
                    elseif strcmp(oErrorFromTileClass.identifier, "Tile:TileMaskDoesNotExist")
                        warning("The following tile's mask was not found in the directory and "...
                            +"therefore skipped: " + stTilePaths(i).name);
                    else
                        rethrow(oErrorFromTileClass);
                    end
                    
                end
                
                if mod(i, 1000) == 0
                    disp(string(i/length(stTilePaths)*100) + "% done");
                end
                
            end
            
            
        end
        
        function obj = FillWithTileObjs(obj,varargin)
            % Usage:
            % voTile = Tile.empty(0, X);
            % Fill voTile with X Tile objects
            % oTiles = FillWithTileObjs(Tiles(),voTile);
            
            % It also looks like I may be able to use it as:
            % oClassifiedTiles = FillWithTileObjs(ClassifiedTiles(), 'ClassifiedTile',voClassifiedTile);
            % I will need to double check this.
            
            
            % 2 - Fill container mode
            % If either more than one argument was given or one argument that isn't character array
            % was given.
            if ~((nargin > 2) || (nargin == 2 && ~ischar(varargin{1}))) % need to check this
                error("Inputs bad.");
            end
            
            % If this function call is made from a subclass specifying the type to hold
            % use that type, otherwise default to Tile.
            if isa(varargin{1} , 'char')
                chTypeItCanHold =  varargin{1};
                c1oTileObjs = varargin{2:end}; % this is because the first arg needs to be skipped if a type is specified
            else
                chTypeItCanHold = 'Tile';
                c1oTileObjs = varargin(1:end);
            end
            % Check that the container is holding the right type
            
            for j = 1 : length(c1oTileObjs)
                if isa(c1oTileObjs{j}, chTypeItCanHold)
                    obj.voTiles = [obj.voTiles , c1oTileObjs{j}];
                    
                else
                    error("This container can only hold objects of type" +...
                        chTypeItCanHold + ", you gave it objects of another type as input.");
                end
            end
        end
        
        function obj = SelectOneCenter(obj, chCenterID)
            vbSelectedTiles = false(length(obj.voTiles));
            
            for i = 1 : length(obj.voTiles)
                if strcmp(obj.voTiles(i).chPatientID(6:7), chCenterID)
                    vbSelectedTiles(i) = true;
                end
            end
            
            obj.voTiles = obj.voTiles (vbSelectedTiles);
        end
        
        function obj = SelectPercentInMask(obj, dMinPerecnt)
            
            vbSelectedTiles = false(length(obj.voTiles),1);
            
            for i = 1 : length(obj.voTiles)
                
                % Include images at or higher than the specified minumum percentage
                if obj.voTiles(i).dPercentInContour >= dMinPerecnt
                    vbSelectedTiles(i) = true;
                end
            end
            
            obj.voTiles = obj.voTiles (vbSelectedTiles);
            
        end
        
        function c1chTilePaths = GetTilePaths(obj)
            c1chTilePaths = cell( 1, length(obj.voTiles ) );
            
            for i = 1 : length(obj.voTiles )
                c1chTilePaths{i} = [obj.voTiles(i).chTileDir, obj.voTiles(i).chTileFilename];
            end
        end
        
        function c1chPatientIDs = GetPatientIDs(obj)
            c1chPatientIDs = cell( 1, length(obj.voTiles ) );
            
            for i = 1 : length(obj.voTiles )
                c1chPatientIDs{i} = obj.voTiles(i).chPatientID;
            end
        end
        
        function c1chSampleIDs = GetSampleIDs(obj)
            c1chSampleIDs = cell( 1, length(obj.voTiles ) );
            
            for i = 1 : length(obj.voTiles )
                c1chSampleIDs{i} = obj.voTiles(i).chSampleID;
            end
        end
        
        function c1chTissueSampleSources = GetTissueSampleSources(obj)
            c1chTissueSampleSources = cell( 1, length(obj.voTiles ) );
            
            for i = 1 : length(obj.voTiles )
                c1chTissueSampleSources{i} = obj.voTiles(i).GetTissueSampleSource();
            end
        end
    
        function [oTrainTiles , oTestTiles, dActualFractionOfGroupsForTraining, dFractionOfSamplesForTraining,...
                c1chTrainGroups, c1chTestGroups] = ...
                SplitIntoTrainAndTestPatients(obj , dFractionGroupsToTrain, NameValueArgs)
            % [oTrainTiles , oTestTiles, dActualFractionOfGroupsForTraining, dFractionOfSamplesForTraining,...
            %   c1chTrainGroups, c1chTestGroups] = SplitIntoTrainAndTestPatients(obj , dFractionGroupsToTrain, 'ByPatientID', true)
            %
            % [oTrainTiles , oTestTiles, dActualFractionOfGroupsForTraining, dFractionOfSamplesForTraining,...
            %   c1chTrainGroups, c1chTestGroups] = SplitIntoTrainAndTestPatients(obj , dFractionGroupsToTrain, 'ByTissueSampleSource', true)
            
            arguments
                obj
                dFractionGroupsToTrain (1,1) double
                NameValueArgs.ByPatientID (1,1) logical = false
                NameValueArgs.ByTissueSampleSource(1,1) logical = false
            end
            
            % If neither was set to true, throw an error
            if ~NameValueArgs.ByPatientID && ~NameValueArgs.ByTissueSampleSource
                error("Tiles:SplitIntoTrainAndTestPatients",...
                    "One of the name value arguments: 'ByPatientID' or 'ByTissueSampleSource' "...
                    + "must be set to true.")
            end
            
            % If both were set to true throw an error
            if NameValueArgs.ByPatientID && NameValueArgs.ByTissueSampleSource
                error("Tiles:SplitIntoTrainAndTestPatients",...
                    "Only one of the name value arguments: 'ByPatientID' or 'ByTissueSampleSource' "...
                    + "must be set to true. The other must be left as false (default).")
            end
            
            % Get unique groups
            if NameValueArgs.ByTissueSampleSource
                c1chUniqueGroupIDs = unique(GetTissueSampleSources(obj));
                
            elseif NameValueArgs.ByPatientID
                c1chUniqueGroupIDs = unique(GetPatientIDs(obj));
            end
            
            % Get number of training and testing IDs based on input fraction for training
            iNumGroups = uint64(length(c1chUniqueGroupIDs));
            
            if dFractionGroupsToTrain > 0 && dFractionGroupsToTrain < 1
                iNumTrainGroups = uint64(round( double(iNumGroups) * dFractionGroupsToTrain));
                iNumTestGroups = uint64( iNumGroups - iNumTrainGroups );
                dActualFractionOfGroupsForTraining = double(iNumTrainGroups) / double(iNumGroups);
            else
                error('Please enter a float between 0 and 1 and not equal to either.')
            end
            
            % Error out if not enough patients exist
            if iNumTrainGroups == 0 || iNumTestGroups == 0
                error('Tiles:SplitIntoTrainAndTestPatients:NotEnoughPatient',...
                    ['Not enough patients exist for a train-test split. The tiles provided ',...
                    'refer to a total of ', num2str(iNumGroups), ' patient(s).']);
            end
            
            % Randomly select which groups will go in training. Get iNumTrainGroups values that are
            % between 1 and iNumGroups  to do so.
            vdUniqueTrainGroupIndeces = randperm(iNumGroups, iNumTrainGroups);
            c1chTrainGroups = c1chUniqueGroupIDs( vdUniqueTrainGroupIndeces );
            
            vdUniqueTestGroupIndeces = 1 : iNumGroups;
            vdUniqueTestGroupIndeces(vdUniqueTrainGroupIndeces) = [];
            c1chTestGroups = c1chUniqueGroupIDs( vdUniqueTestGroupIndeces );
            
            % Create a logical vector that mirros the vector of tile objects. As each tile ID is
            % compared to the training group, if it's within the training sample names, it gets set
            % to true. This "picker" vector will later be applied to the vector of tiles to pick
            % out the training ones.
            vbTrainTilePicker = false(1, length(obj.voTiles));
            
            % Use a loop to find the indices of the training patients
            for i = 1 : length(obj.voTiles)
                
                % Get current ID for current tile
                if NameValueArgs.ByTissueSampleSource
                    chCurrentTileGroupID = obj.voTiles(i).GetTissueSampleSource();
                    
                elseif NameValueArgs.ByPatientID
                    chCurrentTileGroupID = obj.voTiles(i).chPatientID;
                end
                
                % If the current sample group ID is in the predetermined list of unqiue training
                % group IDs then set "tile picker" logical vector to true at the current cell
                % mirroring the current sample being considered.
                if any( contains(c1chTrainGroups, chCurrentTileGroupID) )  % I had ~= 0
                    vbTrainTilePicker(i) = true;
                end
            end
            
            dFractionOfSamplesForTraining = sum(vbTrainTilePicker)/length(obj.voTiles);
            
            % Get the opposite of the training tile picker
            vbTestTilePicker = ~vbTrainTilePicker;
            
            % Select the tiles for each dataset
            oTrainTiles = Select(obj, vbTrainTilePicker);
            oTestTiles = Select(obj, vbTestTilePicker);
            
            
        end
        
        function [bIsThereALeak, c1chLeakedGroups] = CheckForLeakageIntoTestSet(obj, oTestTiles, NameValueArgs)
            % [bIsThereALeak, c1chLeakedGroups]  = CheckForLeakageIntoTestSet(oTrainTiles, oTestTiles, 'ByPatientID', true)
            % [bIsThereALeak, c1chLeakedGroups]  = CheckForLeakageIntoTestSet(oTrainTiles, oTestTiles, 'ByTissueSampleSource', true)
            arguments
                obj % This is the training set
                oTestTiles Tiles
                NameValueArgs.ByPatientID (1,1) logical = false
                NameValueArgs.ByTissueSampleSource(1,1) logical = false
            end
            
            % If neither was set to true, throw an error
            if ~NameValueArgs.ByPatientID && ~NameValueArgs.ByTissueSampleSource
                error("Tiles:CheckForLeakageIntoTestSet",...
                    "One of the name value arguments: 'ByPatientID' or 'ByTissueSampleSource' "...
                    + "must be set to true.")
            end
            
            % If both were set to true throw an error
            if NameValueArgs.ByPatientID && NameValueArgs.ByTissueSampleSource
                error("Tiles:CheckForLeakageIntoTestSet",...
                    "Only one of the name value arguments: 'ByPatientID' or 'ByTissueSampleSource' "...
                    + "must be set to true. The other must be left as false (default).")
            end
            
            if NameValueArgs.ByPatientID
                c1chTrainGroupIDs = unique(GetPatientIDs(obj));
                c1chTestGroupIDs = unique(GetPatientIDs(oTestTiles));
                
            elseif NameValueArgs.ByTissueSampleSource
                c1chTrainGroupIDs = unique(GetTissueSampleSources(obj));
                c1chTestGroupIDs = unique(GetTissueSampleSources(oTestTiles));
            end
            
            c1chLeakedGroups = intersect(c1chTrainGroupIDs, c1chTestGroupIDs);
            
            % Set the boolean flag the method returns
            if isempty(c1chLeakedGroups)
                bIsThereALeak = false;
            else
                bIsThereALeak = true;
            end
            
        end
        
        function iNumTotalPatients = GetNumPatients(obj)
            c1chPatientIDs = unique(GetPatientIDs(obj));
            iNumTotalPatients = uint64(length(c1chPatientIDs));
        end
        
        function iNumUniqueTissueSampleSources = GetNumTissueSampleSources(obj)
            c1chUniqueTissueSampleSources = unique(obj.GetTissueSampleSources());
            iNumUniqueTissueSampleSources = uint64(length(c1chUniqueTissueSampleSources));
        end
        
        function obj = Select(obj, viIndicesToSelect)
            obj.voTiles = obj.voTiles(viIndicesToSelect);
        end
        
        function obj = cat(obj, obj2)
            obj.voTiles = [obj.voTiles, obj2.voTiles];
        end
        
        function obj = ResizeTiles(obj, chResizedImageDirPath, iTragetSideLength, chMethod)
            
            for i = 1 : length(obj.voTiles)
                obj.voTiles(i) = ResizeTile(obj.voTiles(i), chResizedImageDirPath, iTragetSideLength, chMethod);
            end
        end
        
        function CopyToNewDir(obj, chNewDir)
            
            arguments
                obj
                chNewDir (1,:) char
            end
            
            % Input sanitization
            if ~isfolder(chNewDir)
                mkdir(chNewDir)
            end
            
            % Removing the parent folder output
            stNewDirContent = dir(chNewDir);
            if strcmp(stNewDirContent(1).name,'.') && strcmp(stNewDirContent(2).name,'..')
                stNewDirContent(1:2) = [];
            end
            
            % Make sure the directory is empty
            if ~isempty(stNewDirContent)
                error("The target directory must be empty. Please provide an alternative directory.")
            end
            
            % Add a '\' if needed
            if ~strcmp(chNewDir(end),'\')
                chNewDir = [chNewDir,'\'];
            end
            
            
            c1chTilePaths = obj.GetTilePaths;
            
            for dTile = 1:length(c1chTilePaths)
                
                chTileSourcePath = c1chTilePaths{dTile};
                chTileDestinationPath = [chNewDir, obj.voTiles(dTile).chTileFilename];
                
                copyfile(chTileSourcePath, chTileDestinationPath);
                
            end
        end
        
    end
    
    methods (Static)
                
        function SplitTilesIntoHasCancerNoCancerFolders(chOrigDir, chFoldersTargetDir)
            % I made this function for the "PathCHA" project.
            % It takes in a directory of tile images and their masks,
            % where the masks can only have 0s or 1s, 1 being cancer, 0
            % being not cancer. It also takes in a directory path where two
            % folders will be made "HasCancer" and "NoCancer" where if a tile's
            % image has any cancer, it will be copied to HasCancer,
            % otherwise it will be copied into NoCancer.
            
            % Add a '\' if needed
            if ~strcmp(chOrigDir(end),'\')
                chOrigDir = [chOrigDir,'\'];
            end
            if ~strcmp(chFoldersTargetDir(end),'\')
                chFoldersTargetDir = [chFoldersTargetDir,'\'];
            end
            
            % Get all label paths
            stMaskPaths = dir([chOrigDir,'TCGA-*-labelled.png']);
            
            if isempty(stMaskPaths)
                error("The target directory does not have any images with a names following this regural expression: '\TCGA-*-labelled.png'.")
            end
            
            % Go through all tiles
            for iTile = 1 : length(stMaskPaths)
                
                chMaskPath = [chOrigDir, stMaskPaths(iTile).name];
                m2iMask = imread(chMaskPath);
                viMaskLabels = unique(m2iMask);
                
                % Error if you encounter a mask with labels that are NOT
                % zero and one
                if any(~ismember(viMaskLabels,[0,1]))
                    error("Only mask labels of 0 or 1 are allowed.")
                end
                chTilePath = strrep(chMaskPath,'-labelled','');
                
                % If the mask has 1s, it has cancer cells. Copy it into the
                % HasCancer folder. Otherwise copy it into the NoCancer
                % folder.
                if (any(any(m2iMask == 1)))
                    chSubDirectory = 'HasCancer\';
                else
                    chSubDirectory = 'NoCancer\';
                end
                
                chFullTargetDir = [chFoldersTargetDir, chSubDirectory];
                if ~exist(chFullTargetDir, 'Dir')
                    mkdir(chFullTargetDir)
                end
                
                copyfile(chTilePath, chFullTargetDir)
            end
        end
        
        function ExtractTextFiles(chOrigDir,chTargetDir) % TODO: why is this here?
            strTextFileDir = dir([chOrigDir,'*.txt']);
            if ~exist(chTargetDir,'dir')
                mkdir(chTargetDir)
            end
            
            for i = 1:length(strTextFileDir)
                chOrigPath = [chOrigDir,strTextFileDir(i).name];
                copyfile(chOrigPath,chTargetDir);
            end
        end
        
        function [bIsThereALeak, c1chLeakedGroups] = CheckForLeakageIntoTestSetFromTables(tTrainTiles, tTestTiles, NameValueArgs)
            % [bIsThereALeak, c1chLeakedGroups] = CheckForLeakageIntoTestSetFromTables(tTrainTiles, tTestTiles,'ByPatientID', true);
            % [bIsThereALeak, c1chLeakedGroups] = CheckForLeakageIntoTestSetFromTables(tTrainTiles, tTestTiles,'ByTissueSampleSource', true);
            
            arguments
                tTrainTiles table
                tTestTiles table
                NameValueArgs.ByPatientID (1,1) logical = false
                NameValueArgs.ByTissueSampleSource(1,1) logical = false
            end
            
            % If neither was set to true, throw an error
            if ~NameValueArgs.ByPatientID && ~NameValueArgs.ByTissueSampleSource
                error("Tiles:CheckForLeakageIntoTestSet",...
                    "One of the name value arguments: 'ByPatientID' or 'ByTissueSampleSource' "...
                    + "must be set to true.")
            end
            
            % If both were set to true throw an error
            if NameValueArgs.ByPatientID && NameValueArgs.ByTissueSampleSource
                error("Tiles:CheckForLeakageIntoTestSet",...
                    "Only one of the name value arguments: 'ByPatientID' or 'ByTissueSampleSource' "...
                    + "must be set to true. The other must be left as false (default).")
            end
            c1chTrainTilePaths = tTrainTiles.Var1;
            c1chTestTilePaths = tTestTiles.Var1;
            
            % Get the patient ID from each tile path
            c1chTrainGroups = cellfun(@(c) regexp(c, 'TCGA-(\w\w-\w\w\w\w)', 'tokens') ,c1chTrainTilePaths);
            c1chTrainGroups = [c1chTrainGroups{:}]; % This reshapes them to be c1ch instead of c1c1ch
            
            c1chTestGroups = cellfun(@(c) regexp(c, 'TCGA-(\w\w-\w\w\w\w)', 'tokens') ,c1chTestTilePaths);
            c1chTestGroups = [c1chTestGroups{:}];
            
            % TSS is the first two charcters of the the patient ID, get that instead of the full ID
            if NameValueArgs.ByTissueSampleSource
                c1chTrainGroups = cellfun(@(c) c(1:2) ,c1chTrainGroups ,'UniformOutput' ,false);
                c1chTestGroups = cellfun(@(c) c(1:2) ,c1chTestGroups, 'UniformOutput' ,false);
            end
            
            % Check for groups in common
            c1chLeakedGroups = intersect(c1chTrainGroups, c1chTestGroups);
            
            % Set the boolean flag the method returns
            if isempty(c1chLeakedGroups)
                bIsThereALeak = false;
            else
                bIsThereALeak = true;
            end
        end
        
        function tVotesPerSlide = GetPerPatientPredictedLabels(c1chTilePaths,viLabel, vdConfidencesOf1, vbPredictedLabel, dMinFractionVotesForPositive)
            
            tPredictedLabelsTest = table(c1chTilePaths,viLabel, vdConfidencesOf1, vbPredictedLabel,...
                'VariableNames',{'Tiles', 'GroundTruth', 'PredictedConfOf1', 'PredictedLabel'});
            
            c1chSlideNames = cell(height(tPredictedLabelsTest),1);
            
            for i = 1:height(tPredictedLabelsTest)
                c1chSlideNames(i) = regexpi(tPredictedLabelsTest.Tiles{i} , '(TCGA-\w\w-\w\w\w\w-[a-zA-Z0-9.\-]+)','match');
                if ~isa(c1chSlideNames{i},'char')
                    error('not char')
                end
            end
            
            tPredictedLabelsTest = addvars(tPredictedLabelsTest, c1chSlideNames, 'Before', 'Tiles');
            
            c1chUniqueSlideNames = unique(c1chSlideNames);
            vdSumOfVotes = zeros(length(c1chUniqueSlideNames),1);
            vdTotalNumberOfTiles = zeros(length(c1chUniqueSlideNames),1);
            vdTruthLabel = nan(length(c1chUniqueSlideNames),1);
            
            tVotesPerSlide = table(c1chUniqueSlideNames, vdSumOfVotes, vdTotalNumberOfTiles,vdTruthLabel);
            
            
            for dTileIdx = 1:height(tPredictedLabelsTest)
                
                for dUniquePtIdx = 1:height(tVotesPerSlide)
                    if strcmp(tPredictedLabelsTest.c1chSlideNames{dTileIdx}, tVotesPerSlide.c1chUniqueSlideNames{dUniquePtIdx})
                        
                        % Get this patient truth label if you haven't already
                        if isnan(tVotesPerSlide.vdTruthLabel(dUniquePtIdx))
                            tVotesPerSlide.vdTruthLabel(dUniquePtIdx) = tPredictedLabelsTest.GroundTruth(dTileIdx);
                        end
                        
                        % sum labels assigned to tiles
                        tVotesPerSlide.vdSumOfVotes(dUniquePtIdx) = ...
                            tVotesPerSlide.vdSumOfVotes(dUniquePtIdx) ...
                            + double(tPredictedLabelsTest.PredictedLabel(dTileIdx));
                        
                        % get total number of tiles
                        tVotesPerSlide.vdTotalNumberOfTiles(dUniquePtIdx) =...
                            tVotesPerSlide.vdTotalNumberOfTiles(dUniquePtIdx) + 1;
                    end
                end
                
                
            end
            
            vdVote = tVotesPerSlide.vdSumOfVotes./tVotesPerSlide.vdTotalNumberOfTiles;
            tVotesPerSlide = addvars(tVotesPerSlide,vdVote,'After', 'vdTotalNumberOfTiles');
            
            vdFinalPrediction = tVotesPerSlide.vdVote > dMinFractionVotesForPositive;
            tVotesPerSlide = addvars(tVotesPerSlide,vdFinalPrediction,'After', 'vdVote');
            
            
        end
        
        function MakeCollagesOfTiles(c1chListOfTilePaths, dMaxNumTilePerCollage, chSavingsBasePath)
            % e.g. c1chTrainDataPositive = tTrainData.Var1(tTrainData.Var2 == 1);
            %      Tiles.MakeCollagesOfTiles(c1chTrainDataPositive(1:50), 100, 'mont')
            arguments
                c1chListOfTilePaths (:,1) cell
                dMaxNumTilePerCollage (1,1) double
                chSavingsBasePath (1,:) char
            end
            
            if length(c1chListOfTilePaths) > dMaxNumTilePerCollage
                % e.g. ig I have 529 images and 100 im per montage, this will make
                % 5 montages of 100s then one of 29. In that case, it iterates 1:6
                for i = 0:floor(length(c1chListOfTilePaths)/dMaxNumTilePerCollage)
                    
                    dStart = (dMaxNumTilePerCollage*i) + 1;
                    
                    % Bandaid for the case of an exact multiple 
                    % e.g. for 500 tiles and max of 100 per collage, 
                    % the loop will try to excute a 6th time but there are
                    % not tiles. Gotta redesign this. 
                    if dStart > length(c1chListOfTilePaths)
                        continue
                    end
                    
                    % Create a special case fot the last loop where the end is the
                    % end index of the list of images
                    if i == floor(length(c1chListOfTilePaths)/dMaxNumTilePerCollage)
                        dEnd = length(c1chListOfTilePaths);
                    else
                        dEnd = dMaxNumTilePerCollage * (i+1);
                    end
                    
                    % Create a collage with a border between images
                    oMontage = montage(c1chListOfTilePaths(dStart:dEnd),'BorderSize',[1 1]);
                    
                    % Save the montages with names describing which dataset they're
                    % from
                    chDataPath = [chSavingsBasePath,'_',num2str(i+1),'.tif'];
                    imwrite(oMontage.CData, chDataPath)
                    
                    close
                end
            else
                % Create a montage with a border between images
                oMontage = montage(c1chListOfTilePaths,'BorderSize',[1 1]);
                
                % Save the montages with names describing which dataset they're
                % from
                chDataPath = [chSavingsBasePath,'.tif'];
                imwrite(oMontage.CData, chDataPath)
                
                close
                
            end
        end
        
    end
end