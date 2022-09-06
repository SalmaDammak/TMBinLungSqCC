classdef SalmasSuperUtilities
    
    methods (Static = true, Access = public)
    
        function bIndexOfMatches = contains_exact(c1chCellArrayToSearch, chCharacterArrayToFind)
            % A function that looks for the exact string/characters array in a cell array
            % contains({'test','testy'}, 'test') returns [1,1]
            % contains_exact({'test','testy'}, 'test') returns [1,0]
            %TODO: move to a more appropriate class      
            
            bIndexOfMatches = false(size(c1chCellArrayToSearch,1), size(c1chCellArrayToSearch,2));
            for i = 1:size(c1chCellArrayToSearch,1)
                for j = 1:size(c1chCellArrayToSearch,2)
                    if strcmp(c1chCellArrayToSearch{i,j}, chCharacterArrayToFind)
                        bIndexOfMatches(i,j) = true;
                    end
                end
            end
        end
        
    end
end