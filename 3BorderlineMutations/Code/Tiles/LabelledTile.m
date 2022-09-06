classdef LabelledTile < Tile
    properties (SetAccess = immutable) % Can't allow other functions and users to change this
    dMutationCount
    chLabelSourceFile
    end
    
    methods
        function obj = LabelledTile(chTileDir, chTileFilename, oLabel)
            obj = obj@Tile(chTileDir, chTileFilename);
            
            if strcmp(obj.chPatientID, oLabel.chPatientID)
                obj.dMutationCount = oLabel.dMutationCount;
                obj.chLabelSourceFile = oLabel.chInfoSourceFilepath;
            else
                error('The label patient ID does not match the tile patient ID.')
            end
        end
        
        function bEqual = eq(obj,obj2)
            vbEqual =...
                [eq@Tile(obj,obj2),...
                eq(obj.dMutationCount, obj2.dMutationCount),...
                strcmp(obj.chLabelSourceFile, obj2.chLabelSourceFile)];
            
            if any(~vbEqual)
                bEqual = false;
            else
                bEqual = true;
            end           
            
        end
    end
    
end