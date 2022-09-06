classdef TilesTableUtils
    %TileTableUtils
    %
    % A collection of uttilities to prepare and modify the tables
    % containing tile information in the format my python code currently
    % requires it to be. 
    
    % Primary Author: Salma Dammak
    % Created: Jun 22, 2022
    
    
    % *********************************************************************   ORDERING: 1 Abstract        X.1 Public       X.X.1 Not Constant
    % *                            PROPERTIES                             *             2 Not Abstract -> X.2 Protected -> X.X.2 Constant
    % *********************************************************************                               X.3 Private

    properties (Access = public, Constant = true) 
        chImagePathColumnNameInCSV = 'Var1';
        chLabelOrClassColumnNameInCSV = 'Var2';
    end   
    
    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static 
    % *                          PUBLIC METHODS                           *             2 Not Abstract    X.2 Static
    % *********************************************************************

    methods (Access = public, Static = true) 
        
        function [output1, output2] = Function1(input1, input2, varargin) % DELETE IF UNUSED
            %[output1, output2] = Function1(input1, input2, varargin)
            %
            % SYNTAX:
            %  [output1, output2] = function1(input1, input2)
            %  [output1, output2] = function1(input1, input2, 'Flag', input3)
            %
            % DESCRIPTION:
            %  Description of the function
            %
            % INPUT ARGUMENTS:
            %  input1: What input1 is
            %  input2: What input2 is. If input2's description is very, very
            %          long wrap it with tabs to align the second line, and
            %          then the third line will automatically be in line
            %  input3: What input3 is
            %
            % OUTPUTS ARGUMENTS:
            %  output1: What output1 is
            %  output2: What output2 is
            
            % Primary Author: Your name here
            % Created: MMM DD, YYYY
            
            output1 = input1;
            output2 = input2;
        end        
    end
end

