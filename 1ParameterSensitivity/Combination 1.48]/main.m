% Parameters
chSplitCode = '008';
chLearningRate =  '0.01';
chBatchSize = '100';
chEpochs = '20';

%=========================================================================%
% Create collages of the original input data
Experiment.StartNewSection('Original input data')
%=========================================================================%
load(Experiment.GetDataPath(['SP-',chSplitCode]), 'tTestData', 'tTrainData')
dMaxNumTilesInCollage = 100;

% Train positive
c1chTrainDataPositive = tTrainData.Var1(tTrainData.Var2 == 1);
chImageBaseName = [Experiment.GetResultsDirectory(),'\TrainPositive'];
Tiles.MakeCollagesOfTiles(c1chTrainDataPositive, dMaxNumTilesInCollage, chImageBaseName)

% Train negative
c1chTrainDataNegative = tTrainData.Var1(tTrainData.Var2 == 0);
chImageBaseName = [Experiment.GetResultsDirectory(),'\TrainNegative'];
Tiles.MakeCollagesOfTiles(c1chTrainDataNegative, dMaxNumTilesInCollage, chImageBaseName)

% Test positive
c1chTestDataPositive = tTestData.Var1(tTestData.Var2 == 1);
chImageBaseName = [Experiment.GetResultsDirectory(),'\TestPositive'];
Tiles.MakeCollagesOfTiles(c1chTestDataPositive, dMaxNumTilesInCollage, chImageBaseName)

% Test negative
c1chTestDataNegative = tTestData.Var1(tTestData.Var2 == 0);
chImageBaseName = [Experiment.GetResultsDirectory(),'\TestNegative'];
Tiles.MakeCollagesOfTiles(c1chTestDataNegative, dMaxNumTilesInCollage, chImageBaseName)

%=========================================================================%
Experiment.StartNewSection('In python')
%=========================================================================%
% Create datapaths in the format python uses
sTrainDataCSVPath = strrep(Experiment.GetDataPath(['SP-', chSplitCode, '-train-csv']),'\','\\');
sTestDataCSVPath = strrep(Experiment.GetDataPath(['SP-', chSplitCode, '-test-csv']),'\','\\');
sResultsDir = [strrep(Experiment.GetResultsDirectory,'\','\\'),'\\'];

% Set up parameters as strings to be parsed by python script to the correct
% type
chExpFolderName = pwd();
chExpFolderName = chExpFolderName(end-11:end);

c1chPythonScriptArguments = {sTrainDataCSVPath, sTestDataCSVPath, sResultsDir,...
    chEpochs, chLearningRate, chBatchSize, chExpFolderName};

% Run the python code
PythonUtils.ExecutePythonScriptInAnacondaEnvironment(...
    'main.py', c1chPythonScriptArguments,'C:\Users\sdammak\miniconda3', 'keras_env');

% Load the mat file python drops its MATLAB-compatible variables in
% This has: viTruth and vsiConfidences where si means single 
load([Experiment.GetResultsDirectory(),'\Workspace_in_python.mat'])

%=========================================================================%
Experiment.StartNewSection('In MATLAB')
%=========================================================================%
% Check for alignment between matlab and python - Filenames
vsFilenamesFromMATLAB = strtrim(string(tTestData.Var1)); 
vsFilenamesFromPython = strtrim(string(vsFilenames));

if any(~(vsFilenamesFromMATLAB == vsFilenamesFromPython))
    save([Experiment.GetResultsDirectory(),'\ErrorWorkspace.mat']);
    error("MATLAB and Python test set filenames are not aligned")
end

% Check for alignment between matlab and python - Ground truth
vbRowsTheTestTableIsNotEqualToGroundTruth = double(tTestData.Var2) ~= double(viTruth');
if any(vbRowsTheTestTableIsNotEqualToGroundTruth)
    error('The MATLAB tTestTable is not aligned with Python ground truth. Cannot create collages of classification results.')
end

% Calculate metrics using BOLT
disp(newline + "Per tile error metrics: ")
iPositiveLabel = int32(1);
[dAUC, dThreshold, dAccuracy, dTrueNegativeRate, dTruePositiveRate, ...
    dFalseNegativeRate, dFalsePositiveRate, tExcelFileMetrics]=...
    CalculateAllTheMetrics(viTruth', double(vsiConfidences), iPositiveLabel);

% Calculate per patient metrics using BOLT
disp(newline + "Per patient error metrics: ")
[c1chUniqueIDs, vdConfidenceOfOnePerPatient, viTruthPerPatient ,c1vdConfidenceOfOnePerPatient] ...
                = ClassifiedTiles.AggregateConfidencesPerPatient(...
                tTestData.Var1, vsiConfidences, tTestData.Var2,'dThreshold', dThreshold);
viTruthPerPatient = int32(viTruthPerPatient);

[dPerPatientAUC, dPerPatientThreshold, dPerPatientAccuracy, dPerPatientTrueNegativeRate, dPerPatientTruePositiveRate, ...
    dPerPatientFalseNegativeRate, dPerPatientFalsePositiveRate, tPerPatientExcelFileMetrics]=...
    CalculateAllTheMetrics(viTruthPerPatient, vdConfidenceOfOnePerPatient, iPositiveLabel);

save([Experiment.GetResultsDirectory(),'\Excel error metrics.mat'], 'tExcelFileMetrics', 'tPerPatientExcelFileMetrics')


%=========================================================================%
Experiment.StartNewSection('Qualitative classification results')
%=========================================================================%
% Create collages of classification results

vbPredictions = vsiConfidences >= dThreshold;
vbTruePositive = false(length(viTruth), 1);
vbTrueNegative = false(length(viTruth), 1);
vbFalsePositive = false(length(viTruth), 1);
vbFalseNegative = false(length(viTruth), 1);

for iTile = 1:length(viTruth)
    
    bTruthOfOne = boolean(viTruth(iTile));
    bPredictionOfOne = vbPredictions(iTile);
    
        % True positive
    if bTruthOfOne && bPredictionOfOne
        
        vbTruePositive(iTile) = true;
        
        % True negative
    elseif ~bTruthOfOne && ~bPredictionOfOne
        vbTrueNegative(iTile) = true;
        
        % False positive
    elseif ~bTruthOfOne && bPredictionOfOne
        vbFalsePositive(iTile) = true;
        
        % False negative
    elseif bTruthOfOne && ~bPredictionOfOne
        vbFalseNegative(iTile) = true;
        
    end
    
end

% Add to the table and make collages
tTestDataResults = addvars(tTestData, vbPredictions, vbTruePositive,...
    vbTrueNegative, vbFalsePositive, vbFalseNegative,...
    'NewVariableNames',{'Pred', 'TP','TN','FP','FN'});

dMaxNumTilesInCollage  = 25;

try
% True positive
c1chTruePositiveTiles = tTestData.Var1(tTestDataResults.TP == 1);
chImageBaseName = [Experiment.GetResultsDirectory(),'\TruePositive'];
Tiles.MakeCollagesOfTiles(c1chTruePositiveTiles, dMaxNumTilesInCollage, chImageBaseName)
catch 
    warning("No TPs")
end

try
% True negative
c1chTrueNegativeTiles = tTestData.Var1(tTestDataResults.TN == 1);
chImageBaseName = [Experiment.GetResultsDirectory(),'\TrueNegative'];
Tiles.MakeCollagesOfTiles(c1chTrueNegativeTiles, dMaxNumTilesInCollage, chImageBaseName)
catch 
    warning("No TNs")
end

try
% False positive
c1chFalsePositiveTiles = tTestData.Var1(tTestDataResults.FP == 1);
chImageBaseName = [Experiment.GetResultsDirectory(),'\FalsePositive'];
Tiles.MakeCollagesOfTiles(c1chFalsePositiveTiles, dMaxNumTilesInCollage, chImageBaseName)
catch 
    warning("No FPs")
end

try
% False negative
c1chFalseNegativeTiles = tTestData.Var1(tTestDataResults.FN == 1);
chImageBaseName = [Experiment.GetResultsDirectory(),'\FalseNegative'];
Tiles.MakeCollagesOfTiles(c1chFalseNegativeTiles, dMaxNumTilesInCollage, chImageBaseName)
catch 
    warning("No FNs")
end

save([Experiment.GetResultsDirectory(),'\Workspace_in_MATLAB.mat'])

function [dAUC, dThreshold, dAccuracy, dTrueNegativeRate, dTruePositiveRate, ...
    dFalseNegativeRate, dFalsePositiveRate, tExcelFileMetrics]=...
    CalculateAllTheMetrics(viTruth, vdConfidences, iPositiveLabel)

dAUC = ErrorMetricsCalculator.CalculateAUC(viTruth, vdConfidences, iPositiveLabel);
disp("MATLAB AUC: " + num2str(dAUC,'%.2f'))

dThreshold = ErrorMetricsCalculator.CalculateOptimalThreshold(...
    {"upperleft","MCR"}, viTruth, vdConfidences, iPositiveLabel);

dMisclassificationRate = ErrorMetricsCalculator.CalculateMisclassificationRate(...
    viTruth, vdConfidences, iPositiveLabel,dThreshold);
dAccuracy = 1 - dMisclassificationRate;
disp("MATLAB accuracy is: " + num2str(round(100*(1-dMisclassificationRate)))+ "%")

dTrueNegativeRate = ErrorMetricsCalculator.CalculateTrueNegativeRate(...
    viTruth, vdConfidences, iPositiveLabel,dThreshold);
disp("MATLAB TNR is: " + num2str(round(100*(dTrueNegativeRate)))+ "%")

dTruePositiveRate = ErrorMetricsCalculator.CalculateTruePositiveRate(...
    viTruth, vdConfidences, iPositiveLabel,dThreshold);
disp("MATLAB TPR is: " + num2str(round(100*(dTruePositiveRate))) + "%")

dFalseNegativeRate = ErrorMetricsCalculator.CalculateFalseNegativeRate(...
    viTruth, vdConfidences, iPositiveLabel,dThreshold);

dFalsePositiveRate = ErrorMetricsCalculator.CalculateFalsePositiveRate(...
    viTruth, vdConfidences, iPositiveLabel,dThreshold);

tExcelFileMetrics = table(dAUC, dThreshold, dAccuracy, dTrueNegativeRate, dTruePositiveRate);
end