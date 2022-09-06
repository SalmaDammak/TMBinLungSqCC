classdef TCGAUtilities
    %TCGAUtilities
    %
    % This is collection of utilities that help with getting information 
    % from files named in the TCGA convention, parsing TCGA documents, 
    % or selecting subsets of TCGA slides from a pool of slides. 
     
    % Primary Author: Salma Dammak
    % Created: Jun 22, 2022
    
       
    % *********************************************************************   ORDERING: 1 Abstract        X.1 Public       X.X.1 Not Constant
    % *                            PROPERTIES                             *             2 Not Abstract -> X.2 Protected -> X.X.2 Constant
    % *********************************************************************                               X.3 Private

    properties (Access = public, Constant = true) 
        
        % In the SampleName: TCGA-AA-BBBB-CCC-DDD-EEEE-FF
        % TCGA-AA-BBBB is the patient ID, and AA is the tissue sample source. The reminaing bit doesn't
        % follow documented convention as informed by CDG help desk. Helpful links:
        % https://docs.gdc.cancer.gov/Encyclopedia/pages/TCGA_Barcode/
        % https://gdc.cancer.gov/resources-tcga-users/tcga-code-tables
        
        chSampleIDExpression = 'TCGA-\w\w-\w\w\w\w-[a-zA-Z0-9.\-]+';
        chPatientIDExpression = 'TCGA-\w\w-\w\w\w\w';
        chTSSExpression = 'TCGA-\w\w'
    end   
    
     
    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static 
    % *                          PUBLIC METHODS                           *             2 Not Abstract    X.2 Static
    % *********************************************************************
    
    methods (Static = true, Access = public)
        function [dNumUniqueTSS, dNumUniquePatients,vsUniquePatientIDs, vsUniqueTSS,...
                vsPatientIDs, vsTSS] = GetSlideInformationFromSlideNames(vsSlides)
            
            arguments
                vsSlides (1,:) string
            end
            
            vsPatientIDs = string(cellfun(@(s) s(1:12), cellstr(vsSlides), 'UniformOutput', false));
            vsUniquePatientIDs = unique(vsPatientIDs);
            dNumUniquePatients = length(vsUniquePatientIDs);
            
            vsTSS = string(cellfun(@(s) s(1:7), cellstr(vsSlides), 'UniformOutput', false));
            vsUniqueTSS = unique(vsTSS);
            dNumUniqueTSS = length(vsUniqueTSS);
            
        end
        
        function [vsSlides,dNumUniqueTSS, dNumUniquePatients,vsUniquePatientIDs, vsUniqueTSS,...
                vsPatientIDs, vsTSS] = GetSlideInformationFromSlideNamesTextFile(chTextFileLocation)
            
            chSlides = strtrim(fileread(chTextFileLocation));
            c1chSlides = strsplit(chSlides,'\n');
            vsSlides = string(c1chSlides);
            
            
            [dNumUniqueTSS, dNumUniquePatients,vsUniquePatientIDs, vsUniqueTSS,...
                vsPatientIDs, vsTSS] = TCGAUtilities.GetSlideInformationFromSlideNames(vsSlides);
        end
        
        function c1chIDForEachTiles = GetPatientIDsFromTileFilepath(c1chTileFilePaths)
            arguments
                c1chTileFilePaths (:,1) cell {mustBeText}
            end
            
            [~,c1chTileFileNames,~] = fileparts(c1chTileFilePaths);
            c1chIDForEachTiles = cellfun(@(c) regexpi(c,TCGAUtilities.chPatientIDExpression,'match'),...
                c1chTileFileNames, 'UniformOutput', false);
            
            vdEmptyRows = cellfun(@(c) isempty(c), c1chIDForEachTiles);
            
            if any(vdEmptyRows)
                error("One or more IDs could not be obtained from the list of file names of paths you provided. " + ...
                    "Ensure that they have a string with this format " + string(TCGAUtilities.chPatientIDExpression))

            end
                
            c1chIDForEachTiles = [c1chIDForEachTiles{:}]'; 
            
            if length(c1chIDForEachTiles) ~= length(c1chTileFilePaths)
                error("The number of output IDs is different than the number of input filenames. Something went wrong.")
            end
        end
        
        function c1chTSSForEachTile = GetTSSFromTileFilepath(c1chTileFilenames)
            arguments
                c1chTileFilenames (:,1) cell {mustBeText}
            end
            
            c1chTSSForEachTile = cellfun(@(c) regexpi(c,TCGAUtilities.chTSSExpression,'match'),...
                c1chTileFilenames, 'UniformOutput', false);
            
            vdEmptyRows = cellfun(@(c) isempty(c), c1chTSSForEachTile);
            
            if any(vdEmptyRows)
                error("One or more IDs could not be obtained from the list of file names of paths you provided. " + ...
                    "Ensure that they have a string with this format " + string(TCGAUtilities.chTSSExpression))

            end
                
            c1chTSSForEachTile = [c1chTSSForEachTile{:}]'; 
        end
    end
end