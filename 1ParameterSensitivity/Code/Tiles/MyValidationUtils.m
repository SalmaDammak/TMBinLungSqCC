classdef MyValidationUtils
    
    methods (Static = true, Access = public)
        
        function MustBeDirPath(chDirPath)
            arguments
                chDirPath (1,:)
            end
            
            % Directory paths must end in a backslash
            if ~strcmp(chDirPath(end),'\')
                error("Directory paths must end in a backslash.")
            end
            
        end
        
        function MustBeExistingDir(chDirPath)
            arguments
                chDirPath (1,:)
            end
            
            if ~exist(chDirPath, 'Dir')
                error("Directory does not exist.")
            end
        end
        
        function MustBeNonEmptyDir(chDirPath)
            arguments
                chDirPath (1,:)
            end
            
            stDirContent = dir(chDirPath);
            
            % Remove the '.' '..' since they artificially makt eht
            % directory look non-empty
            stDirContent = stDirContent(~ismember({stDirContent.name},{'.','..'}));

            if isempty(stDirContent)
                error("The target directory is empty. Please provide an alternative directory that isn't.")
            end
        end
        
    end
end