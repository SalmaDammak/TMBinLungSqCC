classdef LabelledTiles < Tiles

    
    methods (Access = public, Static = false)
        function obj = LabelledTiles()
            obj = obj@Tiles();
        end
                
        function obj = FillFromDir(obj, chTileDirPath, oLabels)  
            obj = FillFromDir@Tiles(obj, chTileDirPath);
 
            voLabelledTiles = LabelledTile.empty(0, length(obj.voTiles));
            
            if  ~isa(oLabels, 'Labels')
                error("second input must be of type Labels");
            end
                for i = 1 : length(obj.voTiles)
                    chTilePatientID = obj.voTiles(i).chPatientID;
                    
                    for j = 1 : length(oLabels.voLabels)
                        chLabelPatientID = oLabels.voLabels(j).chPatientID;
                        
                        if strcmp(chTilePatientID , chLabelPatientID)
                                                        
                            voLabelledTiles(i) = LabelledTile(obj.voTiles(i).chTileDir, ...
                                obj.voTiles(i).chTileFilename, oLabels.voLabels(j));
                        end
                        
                    end
                    
                end
               obj.voTiles = voLabelledTiles;

        end
        
        function obj = FillWithTileObjs(obj, varargin)
            obj = FillWithTileObjs@Tiles(obj,'LabelledTile', varargin);
        end
        
        function vdLabels = GetLabels(obj)
            vdLabels = nan( 1, length(obj.voTiles ) );
            
            for i = 1 : length(obj.voTiles )
                vdLabels(i) = obj.voTiles(i).dMutationCount;
            end
        end   
        
        function [c1chUniquePatientIDs, c1chUniqueLabels] = GetUniquePatientIDsAndTheirLabels(obj)
            % BIG CAVEAT: THIS ASSUMES THAT NO PATIENT HAS MORE THAN ONE
            % SLIDE
            
            % Make sure that the input object doesn't have more than one
            % slide per patient
            c1chUniquePatientIDs = unique(obj.GetPatientIDs());
            c1chUniqueSlides = unique(obj.GetSampleIDs);
            if length(c1chUniquePatientIDs) ~= length(c1chUniqueSlides)
                error("The number of samples per patient is not equal to one in this tile object. " +... 
                "This function requires that.")
            end
            
            % vdFirstInstanceOfUniquePatientID: this corresponds
            % to the location of the first instance of it in the
            % non-unique input vecto            
            [c1chUniquePatientIDs, vdFirstInstanceOfUniquePatientID]= unique(obj.GetPatientIDs);
            
           % Get one tile per unique patient to get one mutation value per
           % unique patient
           oOneTilePerUniquePatient = obj.Select(vdFirstInstanceOfUniquePatientID);
           
           % Check ID matching to make sure the labels are aligned
           if any(~strcmp(oOneTilePerUniquePatient.GetPatientIDs(), c1chUniquePatientIDs))
               error("IDs don't match, not sure why, you'll have to examine the code, sorry future me.")
           end 
           
           % Get the number of unique mutations
           c1chUniqueLabels = oOneTilePerUniquePatient.GetLabels();
            
        end
        
        function obj = LabelTiles(obj, voTileObjs, oLabels)
            
            
            if  ~isa(oLabels, 'Labels')
                error("second input must be of type Labels");
            end
            obj.voTiles = LabelledTile.empty(0,length(voTileObjs));
            
            for i = 1 : length(voTileObjs)
                chTilePatientID = voTileObjs(i).chPatientID;
                
                for j = 1 : length(oLabels.voLabels)
                    chLabelPatientID = oLabels.voLabels(j).chPatientID;
                    
                    if strcmp(chTilePatientID , chLabelPatientID)
                        
                        obj.voTiles(i) = LabelledTile(voTileObjs(i).chTileDir, ...
                            voTileObjs(i).chTileFilename, oLabels.voLabels(j));
                    end
                    
                end
                
            end
        end
    end
    
end