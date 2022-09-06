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
    end
    methods (Static)
        function obj = ClassifiedTileFromLabelledTile(oLabelledTile, dThreshold)
            oLabel = Label(oLabelledTile.chPatientID, oLabelledTile.dMutationCount,...
                oLabelledTile.chLabelSourceFile);
            obj = ClassifiedTile(oLabelledTile.chTileDir, oLabelledTile.chTileFilename, oLabel, dThreshold);
        end
    end
end
