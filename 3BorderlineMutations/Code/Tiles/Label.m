classdef Label
    % This class respresents the mutation count for a patient that is part of the cancer genome atlas
    % (TCGA) dataset. This class holds the patient ID which is a code name generated as explained in
    % G:\Users\sdammak\LUSC\Data\SampleIDCodeMeanings.pdf, the mutation count, and the source raw file
    % for the mutation count. This is built specifically to work with the TCGA dataset.
    
    properties (SetAccess = immutable, GetAccess = public) 
        % Once these are set, they are locked down. We don't want to allow users or functions to 
        % modify them as this can lead to incorrect target values in the machine learning experiment
        % and hence incorrect scientific conclusions from the experiment.
        
        chPatientID
        dMutationCount          % Number of simple somatic mutations
        chInfoSourceFilepath    % Should be a .tsv obtained as explained in G:\Users\sdammak\HowToVideos\HowToGetLabels.wmv
    end
    
    methods (Access = public)
        
        % Constructor
        function  obj = Label(chPatientID, dMutationCount, chInfoSourceFilepath)           
            %obj = Label(chPatientID, dMutationCount, chInfoSourceFilepath)
            % 
            % DESCRIPTION: 
            %  This constructor checks that inputs are of the right format, then sets the properties 
            %  based on what the user gave.
            %  Major steps of teh algorithm are as follows:
            %  1. First input checks
            %  2. Second input checks
            %  3. Third input checks
            %  4. Assign values to obj
            %
            % INPUT ARGUMENTS:
            %  chPatientID: char or string following teh format TCGA-dd-wwww where w is an upper
            %   case alaphabetic character or a digit.
            %  dMutationCount: numeric (float or int is fine) real positive number indicating the 
            %   number of simple somatic mutations.
            %  chInfoSourceFilepath: char or string filepath to the tsv file the mutation count was
            %   taken from.

            
            %%% 1. First input checks
            % Check that patient ID is a string or char
            if ~( isa(chPatientID, 'char') || isa(chPatientID, 'string') )
            error("Label:InvalidInputForPatientID","The first input chPatientID must be of string " +...
                "or char type.");
            end
                
            % Check that the patient ID follows the TCGA fomat 
            cPtaientIDMatch = regexp(chPatientID,...
                'TCGA-[0-9A-Z][0-9A-Z]-[0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z]','match');
                        
            % If the patient ID does not follow the TCGA experiment format or the formatted ID is
            % embedded in other text, prompt the user to correct it
            if isempty(cPtaientIDMatch) || ~strcmp(cPtaientIDMatch{:}, chPatientID)
                error("Label:InvalidInputForPatientID",...
                    "The patient ID must follow the format: TCGA-ww-wwww where " +...
                    "w is an upper case alaphabetic character or a digit.");
            end
            
            %%% 2. Second input checks
            % Check that the the mutation count is number that's real and positive
            if ~isnumeric(dMutationCount) || ~isreal(dMutationCount) || dMutationCount < 0
                error("Label:InvalidInputForMutationCount","The number entered for mutation count" + ...
                    " must be numeric, real, and greater or equal to zero.");
            end
            
            %%% 3. Third input checks
            % Check that the source file path is char or string
            if ~( isa(chInfoSourceFilepath, 'char') || isa(chInfoSourceFilepath, 'string') )
            error("Label:InvalidInputForSourceFile","The third input chInfoSourceFilepath " +...
                "must be of string or char type.");
            end
            
            % Check that the source file exists on the specified path       
            if exist(chInfoSourceFilepath, 'file') ~= 2 
                error("Label:InvalidInputForSourceFile","The source file you input was not found"+...
                    " or is not a file.");                
            end
            
            % Check that the source file is a .tsv (tab-separated values)
            [~,~,chExt] = fileparts(chInfoSourceFilepath);
            if ~strcmp(chExt, '.tsv')
                error("Label:InvalidInputForSourceFile","The source file you input was not tsv."+...
                    " Source for labels in this project must be .tsv.");
            end
            
            % Check that given label is in file and matches it
            dFoundMutationCount = Label.FindLabelInFile(chPatientID,chInfoSourceFilepath);
            if isnan(dFoundMutationCount)
                error("Label:IncorrectSourceFile", "The patient ID you specified is "....
                    +"not in the file you specified.");
                    
            elseif (dFoundMutationCount ~= dMutationCount)
                error("Label:IncorrectMutationCount", "The value you gave for mutation count does "....
                    +"not match the one in the source file you specified.");
            end
            
            %%% 4. Assign values to obj
            % If all checks are passed assign inputs to properties.
            obj.chPatientID          = char( chPatientID );             % Make into char in case string was given for uniformity
            obj.dMutationCount       = dMutationCount;
            obj.chInfoSourceFilepath = char( chInfoSourceFilepath );    % Make into char in case string was given for uniformity
        end
        
        %%% Over-riding built-ins        
        function disp(obj)
            % Displays the object's information nicely            
            disp([obj.chPatientID,'    ',num2str(obj.dMutationCount),'    ', obj.chInfoSourceFilepath]);
        end        
        function bEqual = eq(obj,oOtherObj)
            % Checks for equality of object to another object of the same type by checking if all
            % of their properties match
            
            % Check that parameter is of the Label type
            if ~isa( oOtherObj , 'Label')
                error("Label:eq:CannotCompareObjectsOfDifferentTypes" , "Objects being compared " +...
                    "must be of the same type.")
            end
            
            % Get a boolean flag result for checking each property
            bPatientIDEqual = strcmp(obj.chPatientID, oOtherObj.chPatientID);
            bMutationCountEqual = ( abs( obj.dMutationCount - oOtherObj.dMutationCount ) < 0.0000001 ); % Use difference with tolerance for floats
            bInfoSourceFilepathSame = strcmp(obj.chInfoSourceFilepath, oOtherObj.chInfoSourceFilepath);
            
            % All flags resolve to true then the objects are equal, and in all other cases they're not 
            if bPatientIDEqual && bMutationCountEqual && bInfoSourceFilepathSame
                bEqual = true;
            else
                bEqual = false;
            end
        end
        function bIsNaN  = isnan(obj)
            % Checks for mutation count equals nan
            bIsNaN = isnan(obj.dMutationCount);
        end
        %%%
    end
    methods (Static)
        function dLabel = FindLabelInFile(chPatientID, chInfoSourceFilepath)
            
            %%% Check that 1st input follows the correct format
            % Check that patient ID is a string or char
            if ~( isa(chPatientID, 'char') || isa(chPatientID, 'string') )
            error("Label:FindLabelInFile:InvalidInputForPatientID","The first input chPatientID must be of string " +...
                "or char type.");
            end
                
            % Check that the patient ID follows the TCGA fomat 
            cPtaientIDMatch = regexp(chPatientID,...
                'TCGA-[0-9A-Z][0-9A-Z]-[0-9A-Z][0-9A-Z][0-9A-Z][0-9A-Z]','match');
                        
            % If the patient ID does not follow the TCGA experiment format or the formatted ID is
            % embedded in other text, prompt the user to correct it
            if isempty(cPtaientIDMatch) || ~strcmp(cPtaientIDMatch{:}, chPatientID)
                error("Label:FindLabelInFile:InvalidInputForPatientID",...
                    "The patient ID must follow the format: TCGA-ww-wwww where " +...
                    "w is an upper case alaphabetic character or a digit.");
            end
            
            %%% Check that 2nd input follows the correct format
            % Must be string or char
            if ~( isa(chInfoSourceFilepath, 'char') || isa(chInfoSourceFilepath, 'string') )
            error("Label:FindLabelInFile:InvalidInputForSourceFile","The second input chInfoSourceFilepath must be of string " +...
                "or char type.");
            end
            % Check that the source file exists on the specified path and is a file
            if exist(chInfoSourceFilepath, 'file') ~= 2
                error("Label:FindLabelInFile:InvalidInputForSourceFile",...
                    "The source file you input was not found"+...
                    " or is not a file.");
            end
            
            % Check that the source file is a .tsv (tab-separated values)
            [~,~,chExt] = fileparts( chInfoSourceFilepath );
            if ~strcmp(chExt, '.tsv')
                error("Label:FindLabelInFile:InvalidInputForSourceFile",...
                    "The source file you input was not tsv."+...
                    " Source for labels in this project must be .tsv.");
            end
                
            % Set label to NaN in case it isn't found
            dLabel = nan;
            
            % Open file and get ID
            dFileID = fopen( chInfoSourceFilepath, 'r' );
            
            iCounter = 0;
            bPatientFound = false;
            
            % As long as the end of the file is not reached AND the patient is not found keep 
            % reading the file line by line.
            while ~feof( dFileID ) && ~bPatientFound
                iCounter = iCounter + 1;
                vchLine = fgetl( dFileID );
                c1chLine = strsplit( vchLine,'\t' );
                
                % Use the first element of the header to find which indices contains match the
                % headers we're looking for
                if iCounter == 1
                    % These header names were hard-coded based on looking at the .tsv file
                    bIdxForchPatientID = contains( c1chLine, 'Case ID' );
                    bIdxForMutationCount = contains( c1chLine, '# Mutations' );
                    
                    % Throw error if matches are not found
                    if sum(bIdxForchPatientID) == 0 || sum(bIdxForMutationCount) == 0
                        error("Labels:WrongHeader",...
                            "The header for the file does not exist or has the wrong values. "...
                            +"Please see G:\\Users\\sdammak\\HowToVideos\\HowToGetLabels' for "...
                            +"how to get label files correctly. The header should be:\n"...
                            + "Select column, Case ID, Project, Primary Site, Gender, Files, Seq,"...
                            +" Exp, SNV, CNV, Meth, Clinical, Bio, # Mutations, # Genes, Slides");
                    end
                    continue
                end
                chCurrentPatientID = c1chLine{ bIdxForchPatientID };
                dCurrentLabel = str2double( c1chLine{ bIdxForMutationCount } );
                
                % Flip the switch for the patient being found to break out of the qhilw loop
                if strcmp(chCurrentPatientID,chPatientID)
                    bPatientFound = true;    
                    dLabel = dCurrentLabel;
                end
            end
            
            % If the patient was not found give the user a warning 
            if ~bPatientFound
                warning("Label:FindLabelInFile:PatientNotFound",...
                    "The patient ID you specified was not found in the file you specified.")
            end
            
        end
    end
    
end
