classdef ClassifiedTile < LabelledTile

    properties
        dThreshold
        bClass       
    end
    
    methods
        function obj = ClassifiedTile(chTileDir, chTileFilename, oLabel, dThreshold)
            
            obj = obj@LabelledTile(chTileDir, chTileFilename, oLabel);
            obj.dThreshold = dThreshold;
            
            if obj.dMutationCount >= dThreshold
                obj.bClass = true;
            elseif obj.dMutationCount < dThreshold
                obj.bClass = false;
            end
        end
        
        function bEqual = eq(obj,obj2)
            vbEqual = ...
                [eq@LabelledTile(obj,obj2),...
                eq(obj.dThreshold, obj2.dThreshold),...
                eq(obj.bClass, obj2.bClass)];
            
            if any(~vbEqual)
                bEqual = false;
            else
                bEqual = true;
            end        
            
            
        end
    end
    methods (Static)
        function obj = ClassifiedTileFromLabelledTile(oLabelledTile, dThreshold)
            oLabel = Label(oLabelledTile.chPatientID, oLabelledTile.dMutationCount,...
                oLabelledTile.chLabelSourceFile);
            obj = ClassifiedTile(oLabelledTile.chTileDir, oLabelledTile.chTileFilename, oLabel, dThreshold);
        end
    end
end
