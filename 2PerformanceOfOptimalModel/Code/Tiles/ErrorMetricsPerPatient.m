% This is useful for unit testing later, DON"T DELETE till equivalent unit test is written for it 

clear 
clc
% load('E:\Users\sdammak\Conferences and presentations\SPIE\SPIE 2020\Experiment\AUC81RunErrorMetrics.mat',...
%     'tPredictedLabelsTest')

load('D:\Users\sdammak\Experiments\LUSC_DL\EXP 000-000-013 [2021-06-22_10.35.00]\Results\04 Qualitative classification results\Workspace_in_MATLAB.mat',...
    'tTestData','vsiConfidences', 'dConfidenceThreshold');
tic
%%% NEW CODE
[c1chUniqueIDs, vdConfidenceOfOnePerPatient, c1vdConfidenceOfOnePerPatient] ...
    = ClassifiedTiles.AggregateConfidencesPerPatient(tTestData.Var1, vsiConfidences, 'dThreshold', dConfidenceThreshold);
toc
tic
%%% OLD CODE
Tiles = tTestData.Var1;
GroundTruth = tTestData.Var2;
PredictedConfOf1 = vsiConfidences;
vbPredictions = (PredictedConfOf1 >= dConfidenceThreshold);
PredictedLabel = vbPredictions;

tPredictedLabelsTest = table(Tiles, GroundTruth, PredictedConfOf1, PredictedLabel);

% Get slide names
c1chSlideNames = cell(height(tPredictedLabelsTest),1);

for i = 1:height(tPredictedLabelsTest)
    c1chSlideNames(i) = regexpi(tPredictedLabelsTest.Tiles{i} , '(TCGA-\w\w-\w\w\w\w-[a-zA-Z0-9.\-]+)','match');
    if ~isa(c1chSlideNames{i},'char')
        error('not char')
    end
end

tPredictedLabelsTest = addvars(tPredictedLabelsTest, c1chSlideNames, 'Before', 'Tiles');

c1chUniqueSlideNames = unique(c1chSlideNames);
vdSumOfVotes = zeros(length(c1chUniqueSlideNames),1);
vdTotalNumberOfTiles = zeros(length(c1chUniqueSlideNames),1);
vdTruthLabel = nan(length(c1chUniqueSlideNames),1);

tVotesPerSlide = table(c1chUniqueSlideNames, vdSumOfVotes, vdTotalNumberOfTiles,vdTruthLabel);


for dTileIdx = 1:height(tPredictedLabelsTest)
    
    for dUniquePtIdx = 1:height(tVotesPerSlide)
        if strcmp(tPredictedLabelsTest.c1chSlideNames{dTileIdx}, tVotesPerSlide.c1chUniqueSlideNames{dUniquePtIdx})
            
            % Get this patient truth label if you haven't already
            if isnan(tVotesPerSlide.vdTruthLabel(dUniquePtIdx))
                tVotesPerSlide.vdTruthLabel(dUniquePtIdx) = tPredictedLabelsTest.GroundTruth(dTileIdx);
            end
            
            % sum labels assigned to tiles
            tVotesPerSlide.vdSumOfVotes(dUniquePtIdx) = ...
                tVotesPerSlide.vdSumOfVotes(dUniquePtIdx) ...
                + double(tPredictedLabelsTest.PredictedLabel(dTileIdx));
            
            % get total number of tiles
            tVotesPerSlide.vdTotalNumberOfTiles(dUniquePtIdx) =...
                tVotesPerSlide.vdTotalNumberOfTiles(dUniquePtIdx) + 1;
        end
    end
    
    
end

vdVote = tVotesPerSlide.vdSumOfVotes./tVotesPerSlide.vdTotalNumberOfTiles;
tVotesPerSlide = addvars(tVotesPerSlide,vdVote,'After', 'vdTotalNumberOfTiles');

vdFinalPrediction = tVotesPerSlide.vdVote > 0.5;
tVotesPerSlide = addvars(tVotesPerSlide,vdFinalPrediction,'After', 'vdVote');
toc
