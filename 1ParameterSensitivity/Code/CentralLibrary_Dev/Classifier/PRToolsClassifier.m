classdef (Abstract) PRToolsClassifier < Classifier
    %PRToolslassifier
    %
    % PRTools Classifier is an ABSTRACT class (cannot be instantiated) that
    % describes the user interface of any PRTools5 classifier in this
    % library. We have shifted away from PRTools so this class and its subclass 
    % PRToolsSVC will simply act as a guide for future developers who want to 
    % use PRTools.
    
    % Primary Author: Salma Dammak
    % Created: Feb 31, 2019
    
    % *********************************************************************   ORDERING: 1 Abstract        X.1 Public       X.X.1 Not Constant
    % *                            PROPERTIES                             *             2 Not Abstract -> X.2 Protected -> X.X.2 Constant
    % *********************************************************************                               X.3 Private
    properties (Abstract = true, SetAccess = immutable, GetAccess = public)
        hClassifier 
    end
    
    properties (Constant = true, GetAccess = protected)
        vsHyperParameterStatesTableHeaders = ...
            ["sName",...
            "c1xValue",...
            "bOptimize",...
            "c1xOptimizationDomain",...
            "sModelParameterName",...
            ];
        
        vsHyperParameterStatesTableColumnTypes = ...
            ["string",...
            "cell",...
            "logical",...
            "cell",...
            "string"];
    end
    
    % *********************************************************************   ORDERING: 1 Abstract     -> X.1 Not Static
    % *                          PUBLIC METHODS                           *             2 Not Abstract    X.2 Static
    % *********************************************************************
    methods (Static = false)
        function obj = PRToolsClassifier(chClassifierHyperParametersFileName, oHyperParameterOptimizer)
            %obj = PRToolsClassifier(chClassifierHyperParametersFileName)
            %
            % SYNTAX:
            %  obj = PRToolsClassifier(chClassifierHyperParametersFileName)
            %
            % DESCRIPTION:
            %  Constructor for PRToolsClassifier. The only thing this does for now is check that
            %       PRTools in on the path and call its super class to read the hyperparameters file.
            %
            % INPUT ARGUMENTS:
            %  chClassifierHyperParametersFileName This is a .mat file containing all the 
            %       hyperparameter information.
            %       A default settings mat file for this classifier is found under: 
            %       BOLT > DefaultInputs > Classifier
            %
            % OUTPUTS ARGUMENTS:
            %  obj: Constructed object
            
            % Primary Author: Salma Dammak
            % Created: Feb 31, 2019
            
            arguments
                chClassifierHyperParametersFileName
                oHyperParameterOptimizer HyperParameterOptimizer {ValidationUtils.MustBeEmptyOrScalar(oHyperParameterOptimizer)}
            end
            
            obj = obj@Classifier(chClassifierHyperParametersFileName);
            
            % Check that PRTools in on the path and is version PRTools5
            try
                classc; % Calls an arbitrary function from the toolbox (can be replaced by any PRTools function)
            catch oMessage                
                if strcmp(oMessage.identifier,'MATLAB:UndefinedFunction')
                    error('PRToolsClassifier:PRToolsNotOnPath',['It appears that the PRTools toolbox ',...
                        'is not included in your path or that the version on your path does not match ',...
                        'ours. Please add PRTools to your path and make sure it is PRTools5.'])
                end
            end  
            
            if ~isempty(oHyperParameterOptimizer)
                obj = OptimizeHyperparameters(obj,oHyperParameterOptimizer);
            end
        end
        
        
        function obj = Train (obj, oLabelledFeatureValues)
            %oTrainedClassifier = Train(obj,oLabelledFeatureValues)
            %
            % SYNTAX:
            % oTrainedClassifier = Train(oClassifier,oLabelledFeatureValues)
            %
            % DESCRIPTION:
            %  Trains a PRTools classifier on a labelled feature values object
            %
            % INPUT ARGUMENTS:
            %  oClassifier: A classifier object
            %  oLabelledFeatureValues: This is a labelled feature values object (class in this 
            %           library) that contains information about the features and the feature values 
            %           themselves. This must only contain the training samples. 
            %
            % OUTPUTS ARGUMENTS:
            %  oTrainedClassifier: input classifier object modified to hold a TrainedClassifier
            %           property that represents the trained model. This is necessary for Guess to 
            %           work. 
            
            % Primary Author: Salma Dammak
            % Created: Feb 31, 2019
            
            arguments
                obj
                oLabelledFeatureValues (:,:) LabelledFeatureValues
            end
            
            if numel(unique(oLabelledFeatureValues.GetLabels())) ~= 2
                error("PRToolsClassifier:Train:NotTwoLabels","This function is built for binary classification only. "+...
                "The Labelled Feature Values you provide must have eaxctly two unique labels.")            
            end
            
            % Change labels to integer 0s and 1s 
            viChangedLabels = GetChangedLabels(oLabelledFeatureValues, int16(1),int16(0));
            
            % Prep PR tools data set 
            oPRTrainingSet = prdataset(GetFeatures(oLabelledFeatureValues),viChangedLabels);
            
            % Get hyperparameters
            c1xClassifierParameters = obj.GetImplementationSpecificParamaters();
            
            iAdaboostParameterIdx = find(cellfun(@(x)strcmp(x,"Adaboost"),obj.tHyperParameterStates{:,'sName'}));
            
            % Check if Adaboost was a possible parameter, and if the user set it to true
            if ~isempty(iAdaboostParameterIdx) && obj.tHyperParameterStates{iAdaboostParameterIdx,'c1xUserInputValue'}{:} == true
                
                % If the classifer is to be combined with Adaboost, call it this way
                obj.oTrainedClassifier = oPRTrainingSet*adaboostc([],obj.hClassifier(c1xClassifierParameters{:}));
            else
                obj.oTrainedClassifier = oPRTrainingSet*obj.hClassifier(c1xClassifierParameters{:});
            end
            
        end
        
        
        function oGuessingResults = Guess(obj, oLabelledFeatureValues)  
            %oGuessingResults = Guess(obj,oLabelledFeatureValues)
            %
            % SYNTAX:
            % oGuessingResults = Guess(oTrainedClassifier,oLabelledFeatureValues)
            %
            % DESCRIPTION:
            %  Based on a trained machine learning model, this function "guesses" the classification
            %  of test samples. 
            %
            % INPUT ARGUMENTS:
            %  oClassifier: A *trained* classifier object. Done using Train
            %  oLabelledFeatureValues: This is a labelled feature values object (class in this 
            %           library) that contains information about the features and the feature values 
            %           themselves. This must only contain the testing (i.e. validation) samples. 
            %
            % OUTPUTS ARGUMENTS:
            %  oGuessingResults: output with samples and associated predicted labels and confidences
            
            % Primary Author: Ryan Alfano
            % Created: Nov 28, 2019
            
            arguments
                obj
                oLabelledFeatureValues (:,:) LabelledFeatureValues
            end

            % Test the classifier against the test set and get list of
            % confidences
            prTestSet = prdataset(GetFeatures(oLabelledFeatureValues));
            prResults = prTestSet * obj.oTrainedClassifier; 
            m2dConfidences = +prResults;

            % PRTools gives confidence of being a 1 in second column when given 0s and 1s. In train, we transform the
            % labels to 0s and 1s with positive label being 1 and this makes it so that in Guess 
            % 2nd column = positive label
            vdPositiveLabelConfidences = m2dConfidences(:,2);

            % Modify output to be encapsulated in guess result class
            oGuessingResults = ClassificationGuessResult(obj, oLabelledFeatureValues, vdPositiveLabelConfidences);
       end
    end
    
    % *********************************************************************
    % *                         PROTECTED METHODS                         *
    % *********************************************************************

    methods (Access = protected)
        % OptimizeHyperparameters
        function obj = ImplementationSpecificOptimizeHyperparameters(obj)
            warning('PRToolsClassifier:NoHyperParamterOptimizationForPRTools',...
                'PRTools currently does not allow for any hyperparameter optimization. No hyperparameters were optimized.')
        end
        function obj = IntializeHyperParameterStatesTable(obj,tHyperParametersFromFile)
            dNumRows = size(tHyperParametersFromFile,1);
            dNumColumns = length(obj.vsHyperParameterStatesTableHeaders);
            
            % Initialize empty table
            obj.tHyperParameterStates =  table('Size',[dNumRows dNumColumns],...
                'VariableTypes',obj.vsHyperParameterStatesTableColumnTypes,...
                'VariableNames', obj.vsHyperParameterStatesTableHeaders);
            
            % Get user inputs
            obj.tHyperParameterStates.sName = tHyperParametersFromFile.sName;
            obj.tHyperParameterStates.sModelParameterName = tHyperParametersFromFile.sModelParameterName;
            obj.tHyperParameterStates.c1xUserInputValue = tHyperParametersFromFile.c1xValue;
            obj.tHyperParameterStates.bOptimize = tHyperParametersFromFile.bOptimize;
            obj.tHyperParameterStates.c1xOptimizationDomain = tHyperParametersFromFile.c1xOptimizationDomain;
            obj.tHyperParameterStates.c1xTrainingResult = obj.tHyperParameterStates.c1xValue;
        end
        function ValidateHyperParameterStatesForOptimization(obj)
            warning('PRToolsClassifier:NoHyperParamterOptimizationForPRTools',...
                'PRTools currently does not allow for any hyperparameter optimization. No hyperparameters were optimized.')
        end
        function obj = SetHyperParameterStatesOptimizableFlag(obj)
            warning('PRToolsClassifier:NoHyperParamterOptimizationForPRTools',...
                'PRTools currently does not allow for any hyperparameter optimization. No hyperparameters were optimized.')
        end
    end
    
    methods (Access = protected, Abstract = true)
        c1xHyperParams = GetImplementationSpecificParamaters(obj) 
        %c1xHyperParams = GetImplementationSpecificParamaters(obj)  
        %
        % SYNTAX:
        %  c1xHyperParams = GetImplementationSpecificParamaters(obj) 
        %
        % DESCRIPTION:
        %  Grabs hyperparameters for classifier training that are specific
        %  to the PRTools classifier
        %
        % INPUT ARGUMENTS:
        %  obj: Classifier object        
        %
        % OUTPUTS ARGUMENTS:
        %  c1xHyperParams: hyper parameters that are in order of how they
        %  should appear as input to the function (PRTools classifiers are
        %  hardcoded this way)
    end
    
    
    
    
    methods (Access = {?KFoldCrossValidationUtils, ?Classifier})
        
        function oGuessingResults = GuessAllowDuplicatedSamples(obj, oLabelledFeatureValues, NameValueArgs)
            arguments
                obj
                oLabelledFeatureValues (:,:) LabelledFeatureValues
                NameValueArgs.JournalingOn (1,1) logical = true
            end
            
            error(...
                'PRToolsClassifier:GuessAllowDuplicatedSamples:Invalid',...
                'This is currently not supported by PRToolsClassifier.');
        end
    end

end