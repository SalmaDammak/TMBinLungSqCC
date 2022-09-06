load(Experiment.GetDataPath('results'),...
    'c1chUniqueIDs','vdConfidenceOfOnePerPatient',...
    'viTruthPerPatient','dFractionTilesPositiveForPositivePatient',...
    'c1vdConfidenceOfOnePerPatient');

% was prediction correct?
viPrediction = vdConfidenceOfOnePerPatient >= dFractionTilesPositiveForPositivePatient;
vdCorrectPrediction = viPrediction == viTruthPerPatient;

% num tiles
vdNumTiles = cellfun(@(c) length(c), c1vdConfidenceOfOnePerPatient);

% tissue area
dTileSideLengthInMicrons = 224 * 0.2520;
vdTissueAreaInMicron2 = vdNumTiles * (dTileSideLengthInMicrons * dTileSideLengthInMicrons);
dMM2inMicron2 = 1/(1000 * 1000);
vdTissueAreaInMM2 = vdTissueAreaInMicron2 * dMM2inMicron2;

% OUTPUT
vdCorrectlyClassifiedPatientsTissueArea = vdTissueAreaInMM2(vdCorrectPrediction);
c1chCorrectlyClassifiedPatients = c1chUniqueIDs(vdCorrectPrediction);

vdIncorrectlyClassifiedPatientsTissueArea = vdTissueAreaInMM2(~vdCorrectPrediction);
c1chIncorrectlyClassifiedPatients = c1chUniqueIDs(~vdCorrectPrediction);

save([Experiment.GetResultsDirectory(),'\Workspace.mat'])
save([Experiment.GetResultsDirectory(),'\OutputOnly.mat'],...
    'vdCorrectlyClassifiedPatientsTissueArea', 'c1chCorrectlyClassifiedPatients',...
    'vdIncorrectlyClassifiedPatientsTissueArea', 'c1chIncorrectlyClassifiedPatients')