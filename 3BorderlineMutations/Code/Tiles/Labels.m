classdef Labels
    % This is a container for the class Label. Its only property is a vector of elements of this
    % type. It "has as" one or more Label objects. Compared to a simple vector of Label objects,
    % this container class adds special functionality related to labels. It allows for removing
    % elements for which the mutational burden is nan, it allows for sorting by patient ID, and for
    % over-riding the unique method to work correctly for Label-type objects.
    
    properties (SetAccess = private)
        % Set access is private to allow modifications on which elements this container holds.
        % This is okay because modifying the container would not lead to incorrect scientific
        % conlusions in an experiment using a container that gets altered.
        % The elements inside it are of type Label that are immutable so there is no risk of actually
        % modifying the label objects within the container.
        voLabels
    end
    
    methods (Access = public)
                
        function obj = Labels(varargin)
            %obj = Labels(chTSVSourceFilePath)
            %obj = Labels(oLabel1, oLabel2, oLabel3, ...oLabeln)
            %
            % DESCRIPTION:
            % obj = Labels(chTSVSourceFilePath)
            %  This format takes a tsv (tab-separated values) file from the TCGA portal that
            %  contains patient ID and mutation count and builds a vector of Label objects
            %  representing all the patients in that TSV file. The file follows a very specific
            %  format. To obtain it follow the instructions explained in the how to video in:
            %  G:\Users\sdammak\HowToVideos\HowToGetLabels.wmv.
            %
            % obj = Labels(oLabel1, oLabel2, oLabel3, ...oLabeln)
            %  This format takes one or more Label objects and contains them in this class.
            %
            % INPUT ARGUMENTS:
            %  chTSVSourceFilePath: char or string indicating path for tsv source file
            %  oLabel: Label object
                        
            
            % First check that that the input follows one of the acceptable formats
            % If not inputs are given
            if nargin == 0
                error("Labels:NotEnoughInputs","You must give at least one input to the constructor.")
                
                % If one input is given but it isn't a char or label type
            elseif nargin == 1 && ~( isa(varargin{1}, 'char') || isa(varargin{1} , 'Label') )
                error("Labels:IncorrectInputType","If you give one input, it must be of type char, "+...
                    " or Label.")
            end
            
            % MODE 1: build vector from tsv file %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % For Mode 1, there would be one input and it would be a string or character array
            if nargin == 1 && ( isa(varargin{1}, 'char') || isa(varargin{1}, 'string') )
                
                %%% Check that input follows the correct format
                % Check that the source file exists on the specified path and is a file
                if exist(varargin{1}, 'file') ~= 2
                    error("Labels:InvalidInputForSourceFile","The source file you input was not found"+...
                        " or is not a file.");
                end
                
                % Check that the source file is a .tsv (tab-separated values)
                [~,~,chExt] = fileparts( varargin{1} );
                if ~strcmp(chExt, '.tsv')
                    error("Labels:InvalidInputForSourceFile","The source file you input was not tsv."+...
                        " Source for labels in this project must be .tsv.");
                end
                
                % Open file and get ID
                dFileID = fopen( varargin{1}, 'r' );
                
                iCounter = 0;
                
                % As long as the end of the file is not reached, keep reading the file line by line.
                while ~feof( dFileID )
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
                                +"Please see G:\\Users\\sdammak\\HowToVideos\\HowToGetLabels.wmv' for "...
                                +"how to get label files correctly. The header should be:\n"...
                                + "Select column, Case ID, Project, Primary Site, Gender, Files, Seq,"...
                                +" Exp, SNV, CNV, Meth, Clinical, Bio, # Mutations, # Genes, Slides");
                        end
                        continue
                    end
                    
                    % Create a Label object for each line (each line is one patient)
                    oLabel = Label( c1chLine{ bIdxForchPatientID }, ...    % chPatientID
                        str2double( c1chLine{ bIdxForMutationCount } ),... % dMutationCount
                        varargin{ 1 });                                    % chInfoSourceFilepath
                    
                    % Each line in the tsv become one element in this container object
                    % Note that the only way to intialize this vector is by reading the file and
                    % counting the lines then reading it to get information. Not worth it for the
                    % current file size of 100 patients.
                    obj.voLabels = [ obj.voLabels, oLabel ];
                    
                end
                
                % Make sure to close the file now that we are done
                fclose( dFileID );
                
                
                % MODE 2: Build vector from collect of Label objects %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            else
                
                % Intialize vector object
                obj.voLabels = Label.empty(0, nargin);
                
                % Loop through cell array of arguments to put into voLabels
                for i = 1 : nargin
                    
                    % Make sure all arguments given are of type label otherwise through error
                    if isa(varargin{i} , 'Label')
                        obj.voLabels(i) = varargin{i};
                    else
                        error("Labels:IncorrectInputType", "If you give one or more inputs that "+...
                            "are not a tsv label source file, they all be of type Label")
                    end
                end
            end
        end

        %%% Over-riding built-ins
        function obj = unique(obj)
            % WORKS BUT HAS LOTS OF DUCT TAPE RIGHT NOW...
            %
            %obj = unique(obj)
            %
            % DESCRIPTION:
            %  Remove all objects that are duplicates and throws errors if any objects have duplicate
            %  patient IDs but different mutation count. If two objects have duplicate patent IDs
            %  and mutation count but different source files, it simply keeps the source file from
            %  the first occurence of this duplicate.
            %
            % ALGORITHM:
            %  This algorithm has the following steps:
            %  1. sort all objects by patient ID
            %  2. iterate through items until the item before last is reached (n-1),
            %   if an item's patient ID does not macth the one that follows it on the list
            %     add the item to a new list and incrementing the counter by 1
            %     if the second-last element is being inspected against the last element, make sure to
            %     also add the last element
            %   else
            %     add the first item to the new list, and increment the counter by 2
            %  3. to deal with multiple duplicates, repeat steps 1 and 2 with making the previous
            %   iteration's output list the original list, and starting a new list for the current
            %   iteration.
            % 4. as soon as the new list has the same size as the old list, we can conclude that no
            %   duplicates are found anymore and we can stop repeating the search process.
            
            
            % Start by assuming duplicates exist
            bDupesExist = true;
            
            % Initialize first version of the original list as the one given by the caller
            oOriginalList = obj;
            
            while bDupesExist %&& length(oOriginalList) > 1
                
                % Create a new list for each iteration
                c1oNewList = {};
                
                %%% 1. Sort the list of orginal objects by patient ID
                oOriginalList = SortByPatientID(oOriginalList);
                                
                % Only continue to run this if more than one element is given, otherwise return the
                % original list.
                if length(oOriginalList) > 1          
                
                % Counter to modify based on whether a duplicate is found
                i = 1;
                
                    %%% 2. Iterate through items until the item before last is reached (n-1)
                    while i < length(oOriginalList)
                        
                        % If an item's patient ID does NOT macth the one that follows it on the list
                        if ~strcmp(oOriginalList.voLabels(i).chPatientID, ...
                                oOriginalList.voLabels(i + 1).chPatientID)
                            
                            % Add it to the new list
                            c1oNewList{i} = oOriginalList.voLabels(i);
                            
                            % If an item's patient ID DOES match the one that follows it on the list..
                        else
                            
                            % ...and if the mutation count is the same for an element and the one
                            % after it (i.e. true dupe!)
                            if oOriginalList.voLabels(i).dMutationCount == ...
                                    oOriginalList.voLabels(i + 1).dMutationCount
                                
                                % keep the first occurence of the dupe that was encountered
                                c1oNewList{i} =  oOriginalList.voLabels(i);
                                
                                % add an extra 1 to the counter to skip over the next element (the
                                % dupe)
                                i = i + 1;
                                
                                % If the mutation count does not match error out because I don't know
                                % how handle that
                            else
                                error("Labels:Unique:SamePatientDifferentMutationCount",...
                                    "A Label object with the same patient ID but a different " +...
                                    "mutation count was found. This function is not equipped to" + ...
                                    "choose which one to keep.")
                            end
                        end
                        
                        % Increment the counter by 1 regardless of what choices were made using the
                        % if statement
                        i = i + 1;
                    end
                    
                    if ~strcmp(oOriginalList.voLabels(end).chPatientID, c1oNewList{end}.chPatientID)
                        c1oNewList{end + 1} = oOriginalList.voLabels(end);
                    end
                
                else
                    c1oNewList{1} = oOriginalList.voLabels(1);                    
                end

                % When no more patients are removed from the list (equal length before and after removal
                % logic), it means that no dupes exist anymore, and the list we have right now is as
                % unique as it will get.
                if length(oOriginalList) == length(c1oNewList)
                    bDupesExist = false;
                end
                
                %%% 3. Make this iterations newList next iteration's originalList to deal with
                % multiple duplicates.
                c1oNewList = c1oNewList(~cellfun('isempty',c1oNewList)); % remove empty elements
                oOriginalList = Labels(c1oNewList{:});
                
            end
            
            % Once no duplicated are found (the new and original lists are of the same length, which
            % also means that they are the same in this function) replace the original labels with
            % the new unique labels.
            obj.voLabels = oOriginalList.voLabels;
        end
        
        function obj = cat(obj, varargin)
            %obj = cat(obj, oLabels1, oLabels2,...oLabels3)
            %
            % DESCRIPTION:
            %  This function concatenates two or more Labels objects into one
            %
            % INPUT ARGUMENTS:
            %  oLabels: Labels object
            
            % Since each oLabels object can have any number of oLabel objects, concatenating in a
            % loop is the quickest way to get all elements
            for i = 1 : length(varargin)
                if isa(varargin{i},'Labels') && isa(obj,'Labels')
                    obj.voLabels = [obj.voLabels, varargin{i}.voLabels];
                else
                    % error out if wrong type is given
                    error("Labels:cat:WrongInputType","All inputs must be of type oLabels.");
                end
            end
        end
        
        function iNumOfElements = length(obj)
            %obj = length(obj)
            %
            % DESCRIPTION:
            %  This function aloows a shortcut for finding the length of the vector in this object,
            %  since this object, is after all, a container.
            %
            % INPUT ARGUMENTS:
            %  obj
            iNumOfElements = length(obj.voLabels);
        end
        
        function disp(obj)
            %obj = disp(obj)
            %
            % DESCRIPTION:
            %  displays all elements in the container
            %
            % INPUT ARGUMENTS:
            %  obj
            
            % Allows user to stop a large objct from displaying in case they just forgot a semicolon
            if length(obj) >500
                strin = input("The element you are trying to display is " + num2str(length(obj))+...
                    " in length, are you sure you want to display it? Y/N\n",'s');
                
                if ~(strcmp(strin, 'Y') || strcmp(strin, 'y') || strcmp(strin, 'yes'))
                    return
                end
            end
            
            % Loop through the object
            for i = 1:length(obj)
                disp(obj.voLabels(i));
            end
        end
        %%%
        
        function obj = SortByPatientID(obj)
            %obj = sortByPatientID(obj)
            %
            % DESCRIPTION:
            %  Sorts all elements in the container by patient ID to allow for an alphabetic search. 
            %  It does this by value. 
            %
            % INPUT ARGUMENTS:
            %  obj
            
            % Get list of all patient IDs
            c1chAllPatientIDs = cell(1 , length(obj.voLabels)) ;
            for i = 1 : length(obj.voLabels)
                c1chAllPatientIDs{i} = obj.voLabels(i).chPatientID;
            end
            
            % Sort by patient ID and get sorting index for that
            [~, viSortingIdx] = sort(c1chAllPatientIDs);
            
            % Rearrange labels
            obj.voLabels = obj.voLabels(viSortingIdx);
        end
        
        function tLabelInfo = ExportToTable(obj, NameValueArgs)
            % vsPatientID | vdMuationCount | vbClass | vsSourceFilePath
            arguments
                obj
                NameValueArgs.dMegabasesPerExome = 30
                NameValueArgs.dTMBCuttoff = 10
            end
            
            dNumLabels = length(obj.voLabels);
            
            % Get the patient IDs, mutation counts, and sourcefiles
            vsPatientID = strings(dNumLabels,1);
            vdMutationCount = nan(dNumLabels,1);
            vsSourceFilePath = strings(dNumLabels,1);
            
            for iLabel = 1:dNumLabels                
                vsPatientID(iLabel) = string(obj.voLabels(iLabel).chPatientID);
                vdMutationCount(iLabel) = obj.voLabels(iLabel).dMutationCount;  
                vsSourceFilePath(iLabel) = string(obj.voLabels(iLabel).chInfoSourceFilepath);
            end
            
            vbClass = (vdMutationCount > (NameValueArgs.dMegabasesPerExome * NameValueArgs.dTMBCuttoff));
            tLabelInfo = table(vsPatientID, vdMutationCount, vbClass, vsSourceFilePath);
        end
        
        function [vdMuationCount, vbClass, tLabelInfo] = GetLabelForSlides(obj, vsSlideNames, NameValueArgs)
            %oLabels.GetLabelForSlides(c1chUniqueIDs)
            arguments
                obj
                vsSlideNames (:,1) string
                NameValueArgs.dMegabasesPerExome = 30
                NameValueArgs.dTMBCuttoff = 10
            end
            
            % Make sure that we're not getting duplicate labels
            obj = obj.unique();
            
            tAllLabelInfo = obj.ExportToTable('dMegabasesPerExome', NameValueArgs.dMegabasesPerExome,...
                'dTMBCuttoff', NameValueArgs.dTMBCuttoff);
            % vsPatientID | vdMuationCount | vbClass | vsSourceFilePath
            
            % Create arrays that will hold the slide information
            vsPatientID = strings(length(vsSlideNames),1);
            vdMuationCount = nan(length(vsSlideNames),1);
            vbClass = false(length(vsSlideNames),1);
            
            % Looping through the slides, find their information in the
            % labels table
            for iSlide = 1:length(vsSlideNames)
                
                % Find get the patient ID from the slide name
                sPatientID = char(vsSlideNames(iSlide));
                sPatientID = sPatientID(1:12);
                sPatientID = string(sPatientID);
                
                % Then find where in the table that patient ID (i.e. slide
                % has a label)
                dLabelIdx = find(tAllLabelInfo.vsPatientID == sPatientID);
                
                % If a slide occurs in two rows in the labels table, error,
                % this shouldn't happen. Also error if the label is nto
                % found.
                if length(dLabelIdx) > 1
                    error(sPatientID + "occurs twice in the labels object you provided.");
                elseif isempty(dLabelIdx)
                    error(sPatientID + "does not exist in the labels object you provided.");
                end
                
                % Get the mutation count, class, and save the patient ID 
                vdMuationCount(iSlide) = tAllLabelInfo.vdMutationCount(dLabelIdx);
                vbClass(iSlide) = tAllLabelInfo.vbClass(dLabelIdx);
                vsPatientID(iSlide) = sPatientID;
            end
                        
            % Put together the table
            tLabelInfo = table(vsSlideNames, vsPatientID, vdMuationCount, vbClass);
        end

    end
    
end

