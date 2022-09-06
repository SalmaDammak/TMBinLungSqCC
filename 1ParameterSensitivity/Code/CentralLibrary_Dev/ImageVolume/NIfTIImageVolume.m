classdef NIfTIImageVolume < ImageVolume
    %ImageVolume
    %
    % ???
    
    % Primary Author: David DeVries
    % Created: Apr 22, 2019
    
    
    % *********************************************************************   ORDERING: 1 Abstract        X.1 Public       X.X.1 Not Constant
    % *                            PROPERTIES                             *             2 Not Abstract -> X.2 Protected -> X.X.2 Constant
    % *********************************************************************                               X.3 Private
     
    properties (SetAccess = immutable, GetAccess = public)
        chFilePath = []
        stFileMetadata = []
    end    
    
    properties (Constant = true, GetAccess = private)
        dQuaternionSumNegativeValueLimit = -1E6;            
    end
    
    
    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static 
    % *                          PUBLIC METHODS                           *             2 Not Abstract    X.2 Static
    % *********************************************************************
        
    methods (Access = public)
        
        function obj = NIfTIImageVolume(chFilePath, varargin)
            %obj = NIfTIImageVolume(chFilePath)
            %obj = NIfTIImageVolume(chFilePath, oRegionsOfInterest)
            %
            % SYNTAX:
            %  obj = NIfTIImageVolume(sFeatureSource, chFilePath, oRegionsOfInterest, sUserDefinedIdTag)
            %  obj = MATLABImageVolume(__, __, __, __, vdDisplayMinMax)
            %
            % DESCRIPTION:
            %  Constructor for NewClass
            %
            % INPUT ARGUMENTS:
            %  input1: What input1 is
            %  input2: What input2 is. If input2's description is very, very
            %         long wrap it with tabs to align the second line, and
            %         then the third line will automatically be in line
            %
            % OUTPUTS ARGUMENTS:
            %  obj: Constructed object
            
            
            stFileMetaData = niftiinfo(chFilePath);
            
            oImageVolumeGeometry = NIfTIImageVolume.GetImageVolumeGeometryFromFileMetaData(stFileMetaData);
                          
            if ~isempty(varargin)
                oRegionsOfInterest = varargin{1};
                
                c1xSuperArgs = {oImageVolumeGeometry, oRegionsOfInterest};
            else
                c1xSuperArgs = {oImageVolumeGeometry};
            end
            
            % super-class constructor
            obj@ImageVolume(c1xSuperArgs{:});            
            
            % set class properities
            obj.chFilePath = chFilePath;
            obj.stFileMetadata = stFileMetaData;
        end
        
        function chFilePath = GetOriginalFilePath(obj)
            chFilePath = obj.chFilePath();
        end
    end
    
    
    
    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static 
    % *                        PROTECTED METHODS                          *             2 Not Abstract    X.2 Static
    % *********************************************************************
    
    methods (Access = protected)
        
        function cpObj = copyElement(obj)
            % super-class call:
            cpObj = copyElement@ImageVolume(obj);
            
            % local call
            % no deep copies required
        end
        
        function m3xImageData = LoadOriginalImageData(obj)
            dMultiplicativeScaling = double(obj.stFileMetadata.MultiplicativeScaling);
            
            if dMultiplicativeScaling == 0 % a multiplicative scaling of "0" is actually "no scaling", which is actually a factor of "1" then. Thanks NIfTI!
                dMultiplicativeScaling = 1;
            end
            
            dAdditiveOffset = double(obj.stFileMetadata.AdditiveOffset);
            
            m3xImageData = niftiread(obj.chFilePath);
            
            if NIfTIImageVolume.GetQFactorFromFileMetadata(obj.stFileMetadata) == -1
                m3xImageData = permute(m3xImageData, [2,1,3]);
            end
                
            if ... % not need to get out integer type
                    dMultiplicativeScaling == floor(dMultiplicativeScaling) && ...
                    dAdditiveOffset == floor(dAdditiveOffset)
                
                chDataClass = class(m3xImageData);
                dImageMax = double(max(abs(m3xImageData(:))));
                
                if abs(dImageMax * dMultiplicativeScaling + dAdditiveOffset) > cast(Inf, chDataClass) % check if it will overflow the format it's in
                    m3xImageData = double(m3xImageData);
                end
            else % if the scaling/offset factors aren't ints, gotta convert to doubles
                m3xImageData = double(m3xImageData);
            end
            
            m3xImageData = m3xImageData * dMultiplicativeScaling + dAdditiveOffset;
        end
    end
    
    
    
    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static
    % *                         PRIVATE METHODS                           *             2 Not Abstract    X.2 Static
    % *********************************************************************
    
    methods (Access = {?NIfTILabelMapRegionsOfInterest}, Static = true)
        
        function oImageVolumeGeometry = GetImageVolumeGeometryFromFileMetaData(stFileMetaData)
            
            % refer to:
            % https://nifti.nimh.nih.gov/nifti-1/documentation/nifti1fields/nifti1fields_pages/quatern.html
            % we're also working in Right/Anterior/Superior (RAS) coordinates
            
            dQuaternionB = stFileMetaData.raw.quatern_b;
            dQuaternionC = stFileMetaData.raw.quatern_c;
            dQuaternionD = stFileMetaData.raw.quatern_d;
            
            dQuaternionSum = 1 - (dQuaternionB.^2) - (dQuaternionC.^2) - (dQuaternionD.^2);
            
            if dQuaternionSum < 0
                if dQuaternionSum < NIfTIImageVolume.dQuaternionSumNegativeValueLimit
                    error(...
                        'NIfTIImageVolume:GetImageVolumeGeometryFromFileMetaData:InvalidQuaternionSum',...
                        ['The sum of the squares of the quaternion components B, C, and D must be less than or equal to one (within ', num2str(NIfTIImageVolume.dQuaternionSumNegativeValueLimit), ').']);
                else
                    dQuaternionSum = 0;
                end
            end
            
            dQuaternionA = sqrt(dQuaternionSum);
            
            vdRowAxisUnitVector = [...
                dQuaternionA.^2 + dQuaternionB.^2 - dQuaternionC.^2 - dQuaternionD.^2,...
                (2 .* dQuaternionB .* dQuaternionC) + (2 .* dQuaternionA .* dQuaternionD),...
                (2 .* dQuaternionB .* dQuaternionD) - (2 .* dQuaternionA .* dQuaternionC)];
            
            vdColAxisUnitVector = [...
                (2 .* dQuaternionB .* dQuaternionC) - (2 .* dQuaternionA .* dQuaternionD),...
                dQuaternionA.^2 + dQuaternionC.^2 - dQuaternionB.^2 - dQuaternionD.^2,...
                (2 .* dQuaternionC .* dQuaternionD) + (2 .* dQuaternionA .* dQuaternionB)];
                   
            vdVolumeDimensions = stFileMetaData.ImageSize;
            
            switch stFileMetaData.SpaceUnits
                case 'Millimeter'
                    vdVoxelDimensions_mm = stFileMetaData.PixelDimensions;
                otherwise
                    error(...
                        'NIfTIImageVolume:Constructor:InvalidVoxelUnits',...
                        [stFileMetaData.SpaceUnits, ' is a currently unsupported voxel unit.']);
            end
            
            vdFirstVoxelPosition_mm = [...
                stFileMetaData.raw.qoffset_x,...
                stFileMetaData.raw.qoffset_y,...
                stFileMetaData.raw.qoffset_z];
            
            dQFactor = NIfTIImageVolume.GetQFactorFromFileMetadata(stFileMetaData);
            
            if dQFactor == -1
                % row and col axis are flipped
                vdTempVector = vdRowAxisUnitVector;
                
                vdRowAxisUnitVector = vdColAxisUnitVector;
                vdColAxisUnitVector = vdTempVector;
                
                vdVolumeDimensions([1,2]) = vdVolumeDimensions([2,1]);
                vdVoxelDimensions_mm([1,2]) = vdVoxelDimensions_mm([2,1]);
            end
            
            oImageVolumeGeometry = ImageVolumeGeometry(...
                vdVolumeDimensions,...
                vdRowAxisUnitVector, vdColAxisUnitVector,...
                vdVoxelDimensions_mm, vdFirstVoxelPosition_mm);
        end
        
        function dQFactor = GetQFactorFromFileMetadata(stFileMetaData)
            % see: 
            % https://nifti.nimh.nih.gov/nifti-1/documentation/nifti1fields/nifti1fields_pages/pixdim.html/document_view
            % https://nifti.nimh.nih.gov/nifti-1/documentation/nifti1fields/nifti1fields_pages/qsform.html
            
            % the Q factor is a factor that basically flips the coordinate
            % axis for the 3rd dimension. If it's -1, the flip occurs,
            % otherwise, no flip            
            
            if stFileMetaData.raw.pixdim(1) == -1
                dQFactor = -1;
            else
                dQFactor = 1;
            end
        end
    end
    
    
    
    % <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    % <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    
    
    
    % *********************************************************************
    % *                        UNIT TEST ACCESS                           *
    % *                  (To ONLY be called by tests)                     *
    % *********************************************************************
    
    methods (Access = {?matlab.unittest.TestCase}, Static = false)        
    end
    
    
    methods (Access = {?matlab.unittest.TestCase}, Static = true)        
    end
end


