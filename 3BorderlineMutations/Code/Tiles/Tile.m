classdef Tile
    properties (SetAccess = immutable, GetAccess = public)
        chOriginalTileDir         % This is the path to directory the full-reolsution tile sits in.
        chOriginalTileFilename    % This is the filename of the full-resolution tile
        % Filename () content format: (resolution, X, Y, width, height)
        % Note that masks associated with the tiles have the same name but end in -labelled.png and
        % must sit in the original tile directory.
        dOriginalTileSideLength   % In pixels. Note that only square tiles are allowed.
        dOriginalPixelSideLength  % In micrometers. Note that we assume that pixel width and length are always equal
        
        % In the name: TCGA-AA-BBBB-CCC-DDD-EEEE-FF
        % TCGA-AA-BBBB is the patient ID, and AA is the tissue sample source. The reminaing bit doesn't
        % follow documented convention as informed by CDG help desk. Helpful links:
        % https://docs.gdc.cancer.gov/Encyclopedia/pages/TCGA_Barcode/
        % https://gdc.cancer.gov/resources-tcga-users/tcga-code-tables
        
        chSampleID                % TCGA-\w\w-\w\w\w\w-[a-zA-Z0-9.\-]+
        chPatientID               % TCGA-\w\w-\w\w\w\w
        vdTilePosition            % This is relative to upper left corner of whole slide image
        dPercentInContour         % How much of the tile is in the contour mask (value range: 0-1)
    end
    
    properties (SetAccess = private)
        % These propeties get changed when a tile is resized that's why they are set to private
        chTileDir                 % This is the path to directory of the tile represnted by this object
        chTileFilename            % This is the name of the tile represnted by this object
        dTileSideLength           % In pixels. Note that only square tiles are allowed.
        dPixelSideLength;         % In micrometers. Note that we assume that pixel width and length are always equal
        
        bResized = false;         % This flag is only flipped if an image is resized
        chResizeAlgorithm = '';   % Nearest neighbour is standard
        dResizeFactor = nan;      % This is the newArea(pixels)/originalArea(pixels). Factors < 1: image was shrunk.
        
    end
    
    methods
        % Constructor
        function obj = Tile(chTileDir , chTileFilename)
            %obj = Tile(chTileDir, chTileFilename);
            %
            % DESCRIPTION:
            %  This constructor checks that inputs are of the right format, then sets the properties
            %  based on what the user gave.
            %  Major steps of the algorithm are as follows:
            %  1. First input checks
            %  2. Second input checks
            %  3. Make sure that the Tile path given is not one for a resized tile
            %  4. Check that mask is in the original tile directory
            %  5. Set the original and current paths both to the paths given by the user
            %  6. Get the sample and patient IDs based on the tile filename
            %  7. Get tile position, size, and resolution information, also from the filename
            %  8. Calculate how much of the tile is in the contour/mask provided
            %
            % INPUT ARGUMENTS:
            %  chTileDir: char directory (folder) path for where the tile is sitting
            %  chTileFilename: char filename of the tile including the .png
            %  chMaskDir: directory (folder) path for where the mask for this tile is sitting
            arguments
                chTileDir  (1,:) {mustBeA(chTileDir, ["string","char"])}
                chTileFilename (1,:) {mustBeA(chTileFilename, ["string","char"])}
            end
            % Add for empty constructor call
            if nargin == 1
                warning('You intilized an empty Tile object.');
            end
            %% 1. First input check
            % Force input dir to be char            
            chTileDir = char(chTileDir);            
            if ~isfolder(chTileDir)
                error("Tile:InvalidInputForTileDir","The tile directory you provided does not exist " +...
                    "or is not a directory.");
            end
            if ~strcmp(chTileDir(end),'\')
                chTileDir = [chTileDir,'\'];
            end
            addpath(chTileDir)
            
            %% 2. Second input check
            % Check that it is charm that it is a Filename, and that it follows a certain format
            chTileFilename = char(chTileFilename);
            if exist(chTileFilename,'file') ~= 2
                error("Tile:InvalidInputForTileFilename","The tile filename you provided does not exist " +...
                    "or is not a filename.");
            end
            if isempty(regexpi(chTileFilename , 'TCGA-\w\w-\w\w\w\w-.+\.png','match'))
%                 if ~isempty(regexpi(chTileFilename , 'resized','match'))
%                     %% 3. Make sure that the Tile path given is not one for a resized tile
%                     % This is a check that's not difficult to get around because it relies on the user using
%                     % this class for resizing but it's better than nothing
%                     error("Tile:TileAlreadyResized", ...
%                         "You cannot re-load a resized tile into the pipeline as it looses informaion " +...
%                         "linking it to the original tile it was obtained from.")
                if isempty(regexpi(chTileFilename , '.png','match'))
                    error("Tile:InvalidInputForTileFilename", ...
                        "The tile file must be of type .png. " +...
                        "linking it to the original tile it was obtained from.")
                else
                    error("Tile:InvalidInputForTileFilename","The tile Filename must follow this format:\n" +...
                        "'TCGA-ww-wwww-[some combination of letters numbers and characters]_" +...
                        "[[some combination of letters numbers and characters]].png', where w is any" +...
                        "letter or digit");
                end
            end
            
            %% 4. Check that mask exists in the original directory
            chMaskPath = strrep([chTileDir,chTileFilename],'.png','-labelled.png');
            if exist(chMaskPath,'file') ~= 2
                error("Tile:TileMaskDoesNotExist","The mask associated with this tile does not exist " +...
                    "or is not in the same directory as the tile.")
            end
            
            %% 5. Set the original and current paths both to the paths given by the user
            obj.chOriginalTileDir = chTileDir;
            obj.chTileDir = chTileDir;
            obj.chOriginalTileFilename = chTileFilename;
            obj.chTileFilename = chTileFilename;
            
            %% 6. Get the sample and patient IDs based on the tile filename
            c1chSampleID = regexpi(chTileFilename , 'TCGA-\w\w-\w\w\w\w-[\w\-\.]+','match');
            obj.chSampleID = c1chSampleID{:};
            obj.chPatientID = obj.chSampleID(1:12);
            
            %% 7. Get tile position, size, and resolution information, also from the filename
            % format: [downsampleFactor*, X, Y, width, height]
            % *downsample factor may or may not be there. d>1 = shrunk from
            % original, d>1, the original pixel side length is less than 0.2520 
            c1chTileInfo = regexpi(chTileFilename , '\[.+\]','match');
            c1chTileInfo = split(c1chTileInfo{1}(2:end-1) , ',');
            vdTileInfoNum = str2double(cellfun(@(c) c(3:end), c1chTileInfo, 'UniformOutput',false));
            
            vbXRow = contains(c1chTileInfo,'x');
            vbYRow = contains(c1chTileInfo,'y'); 
                        
            % X and Y coordinates from upper left corner                       
            obj.vdTilePosition = [vdTileInfoNum(vbXRow), vdTileInfoNum(vbYRow)];
            
            % Make sure only square tiles are used
            stImInfo = imfinfo([chTileDir,'\', chTileFilename]);
            dWidth = stImInfo.Width;
            dHeight = stImInfo.Height;
            if dWidth == dHeight
                obj.dOriginalTileSideLength = dWidth;
                obj.dTileSideLength = dWidth;
            else
                error("Tile:NonSquareTile",...
                    "This Implementation only allows square tiles. The tile input has a width different from its height");
            end
            
            % Tile resolution
            % 0.2520 is the base I use in the QuPath scripts
            vbDownsampleFactorRow = contains(c1chTileInfo,'d');
            if any(vbDownsampleFactorRow)
                obj.dOriginalPixelSideLength = 0.2520/(vdTileInfoNum(vbDownsampleFactorRow));
            else
                obj.dOriginalPixelSideLength = 0.2520;
            end
            obj.dPixelSideLength = obj.dOriginalPixelSideLength;
            
            %% 8. Calculate how much of the tile is in the contour/mask provided
            obj.dPercentInContour = Tile.FindPercentInContour( [obj.chOriginalTileDir, ...
                strrep(obj.chOriginalTileFilename ,'.png','-labelled.png')] );
            
        end
        
        function obj = ResizeTile(obj, chResizedTileDir, iTragetSideLength, chMethod)
            %obj = resizeTile(obj, chResizedTileDir, iTragetSideLength, chMethod)
            %
            % DESCRIPTION:
            %  This method creates a copy on disk of the tile represented by the given object. This
            %  copy is resized to have a side length as specified in the input parameters using the
            %  method also specified in the input parameters. It then modifies the object properties
            %  to retain information about this resizing and change the path to this resized tile
            %  instead of the original one. This method allows for storing the resized tile in
            %  either the original tile directory or a new tile directory. We recommend using a new
            %  directory.
            %
            % INPUT ARGUMENTS:
            %  chResizedTileDir: char directory (folder) path for where the resized tile should go
            %  iTragetSideLength: int an integer value specifying how many pixels should teh side
            %   length of th resized tile be
            %  chMethod: char any of the method specified as input arguments in Matlab's resiz
            %   function here https://www.mathworks.com/help/images/ref/imresize.html#buxswkh-3
            %   we recommend using 'nearest' based on this: https://onlinelibrary.wiley.com/doi/pdf/10.1111/jmi.12477
            
            % Make sure the tile has not been resize by this algorithm before
            % This is not foolproof for never re-resizing a tile, but it's better than nothing
            arguments
                obj
                chResizedTileDir (1,:) {mustBeA(chResizedTileDir, ["string","char"])} 
                iTragetSideLength
                chMethod
            end
            
            if obj.bResized
                error("Tile:resizeTile:CannotResizeResizedTile",...
                    "This implenetation does no allow for resizing an already resized Tile.");
            end
            
            %% 1. Check first input
            % Make sure it's char, create the folder if it doesn't exist, and add a '\' to the end if it
            % doesn't have it
            chResizedTileDir = char(chResizedTileDir);
            if ~isfolder(chResizedTileDir)
                mkdir(chResizedTileDir);
            end
            if ~strcmp(chResizedTileDir(end),'\')
                chResizedTileDir = [chResizedTileDir,'\'];
            end
            
            %% 2. Check second input
            % Make sure it is int and that the requested size won't exceed memory capability
            if ~isa(iTragetSideLength, 'integer')
                error("Tile:ResizeTile:InvalidInputForTragetSideLength","The second input "...
                    + "TragetSideLength must be of int type.");
            end
            
            % Calculate the maximum side length allowed based on the largest matrix this instance of
            % Matlab can accomodate. Make sure to read the original image before doing this in case
            % it substantially affects available memory. Do this as follows:
            
            %   a. Read the original image and mask
            m2dOriginalImage = imread( [obj.chTileDir, obj.chTileFilename] );
                        
            %   b. matrix elements we can use: numElem = memory available / 8 bytes. A doubele element uses 8
            %   bytes in a matrix
            stMemoryAvailable = memory;
            iMemoryAvailableInBytes = stMemoryAvailable.MaxPossibleArrayBytes - stMemoryAvailable.MemUsedMATLAB;
            iNumMatrixElements = iMemoryAvailableInBytes / 8;
            
            %   c. 2D matrix side length: maxSideLength = floor(sqrt(numElem)). Add a fudge factor
            %   to allow for room in memory making other variables. I like 0.75 for this.
            iMaxSideLengthWithFudgeFactor = 0.75 * floor(sqrt(iNumMatrixElements));
            
            if iTragetSideLength <= 0 || iTragetSideLength > 1000%iMaxSideLengthWithFudgeFactor %TODO: fix
                error("Tile:ResizeTile:InvalidInputForTragetSideLength","The second input "...
                    + "TragetSideLength must be a value higher than 0 and lower than  "...
                    + num2str(iMaxSideLengthWithFudgeFactor) + "(max based on currently available memory).");
            end
            
            %% 3. Check the third input
            if ~( isa(chMethod, 'char') )
                error("Tile:ResizeTile:InvalidInputForMethod","The third input chMethod must be of " +...
                    "char type.");
            end
            %% 4. Resize the original image
            % Matlab throws a generic error if given a method that doesn't exist for its function
            % saying that it "expects even inputs". This likely because it can take mut
            try
                m2dResizedTile = imresize(m2dOriginalImage,[iTragetSideLength,iTragetSideLength], chMethod);
            catch e
                if strcmp(e.identifier, "MATLAB:images:imresize:oddNumberArgs")
                    error("Tile:ResizeTile:InvalidInputForMethod","The method you gave did not "...
                        +"match the methods available in Matlab's resize function. Please use one "...
                        +"of those. The mthods are listed under 'method' input argument at "+...
                        "https://www.mathworks.com/help/images/ref/imresize.html#d117e159980 .");
                else
                    rethrow(e)
                end
            end
            
            %% 5. Write the resized image in the given directory
            % Modify the image filename to add info in the title about its resizing
            chResizedTileFilename = strrep(obj.chTileFilename,'.png', ...
                ['_resized_',num2str(iTragetSideLength),'_',chMethod,'.png']);
            imwrite(m2dResizedTile,[chResizedTileDir, chResizedTileFilename]);
            
            
            %% 6. Change object properties to reflect this resize
            obj.bResized = true;
            obj.chTileDir = chResizedTileDir;           % change these to point to resized tile instead of the original tile
            obj.chTileFilename = chResizedTileFilename; % change these to point to resized tile instead of the original tile
            obj.chResizeAlgorithm = chMethod;
            obj.dResizeFactor = (double(iTragetSideLength)^2)/(obj.dOriginalTileSideLength)^2;
            obj.dTileSideLength = double(iTragetSideLength);
            obj.dPixelSideLength = obj.dOriginalPixelSideLength / (obj.dTileSideLength/obj.dOriginalTileSideLength);
        end
        function chTissueSampleSource = GetTissueSampleSource(obj)
            chTissueSampleSource = obj.chPatientID(6:7);
        end
        function bEqual = eq(obj,obj2)
            
            % NaN != NaN so I want to account for that
            if isnan(obj.dResizeFactor) && isnan(obj2.dResizeFactor)
                bResizefactorEq = true;
            else
                bResizefactorEq = eq(obj.dResizeFactor, obj2.dResizeFactor);
            end
            vbEqual =[...
            strcmp(obj.chOriginalTileDir, obj2.chOriginalTileDir),...
            strcmp(obj.chOriginalTileFilename, obj2.chOriginalTileFilename),...
            ...
            eq(obj.dOriginalTileSideLength, obj2.dOriginalTileSideLength),...
            eq(obj.dOriginalPixelSideLength, obj2.dOriginalPixelSideLength),...
            ...
            strcmp(obj.chSampleID, obj2.chSampleID),...
            strcmp(obj.chPatientID, obj2.chPatientID),...
            ...
            eq(obj.vdTilePosition, obj2.vdTilePosition),...
            eq(obj.dPercentInContour, obj2.dPercentInContour),...
            ...
            strcmp(obj.chTileDir, obj2.chTileDir),...
            strcmp(obj.chTileFilename, obj2.chTileFilename),...
            ...
            eq(obj.dTileSideLength, obj2.dTileSideLength),...
            eq(obj.dPixelSideLength, obj2.dPixelSideLength),... 
            eq(obj.bResized, obj2.bResized),...      
            strcmp(obj.chResizeAlgorithm, obj2.chResizeAlgorithm),...
            bResizefactorEq];
            
        if any(~vbEqual)
            bEqual = false;
        else
            bEqual = true;
        end
        end
    end
    
    methods (Static = true)
        
        function dPerecntInContour = FindPercentInContour(chMaskPath)
            %dPerecntOfTileContour = FindPercentInContour(chMaskPath)
            %
            % DESCRIPTION:
            %   This function calculates the fraction of a maks associated with a tile is in the
            %   contour. It expects a mask image that only contains 1s and/or 0s. This method readss
            %   the mask from disk so it can be slow.
            %
            % INPUT ARGUMENTS:
            %   chMaskPath: char path for the mask file
            %
            % OUTPUT ARGUMENTS:
            %   dPerecntInContour: double a value between 0 and 1 indicating the fraction of the
            %   mask in the contour (i.e. equal to 1).
            
            %% 1. Input check
            % Check that mask path is a char and a file
            if ~( isa(chMaskPath, 'char') )
                error("Tile:FindPercentInContour:InvalidInputForMaskPath",...
                    "The input chMaskDir must be of char type.");
            end
            if exist(chMaskPath, 'file') ~= 2
                error("Tile:FindPercentInContour:InvalidInputForMaskPath","The mask path you "...
                    +"provided does not exist or is not a file.");
            end
            
            %% 2. Read the mask image
            ui8Mask = imread(chMaskPath);
            
            %% 3. Calculate percent in mask
            % Make sure that the mask does not contain anything but 1s and 0s. This is expected
            % output from our tile extraction algorithm
            vdUniqueMaskValues = unique(ui8Mask);
            % If it's NOT any of the allowed cases (0,1, or 0s and 1s) throw an errot
            if ~ (isequal(vdUniqueMaskValues, 1) ...
                    || isequal(vdUniqueMaskValues, 0)...
                    || isequal(vdUniqueMaskValues, [0 ; 1] ))
                error("Tile:FindPercentInContour:InvalidMask",...
                    "The masks associated with the tiles must only contains 0s and/or 1s. "...
                    +"The mask you provided the path to has the following values: " +...
                    num2str(vdUniqueMaskValues'));
            end
            
            % Since 1s mean the pixels are in the contour, and teh rest are zero, simply adding the
            % elements in the mask and dividing them by the total number of pixels will give the
            % percent of the tile in the contour
            dPerecntInContour = sum(sum(ui8Mask))/ (size(ui8Mask,1)*size(ui8Mask,2));


            fclose('all');
        end        
        
    end
    
end