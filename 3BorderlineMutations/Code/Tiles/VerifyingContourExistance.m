
chRequestedFilePath = 'D:\Users\sdammak\Experiments\LUSCCancerCells\SlidesToContour\All The Slides That Should have Contours.txt';
fid = fopen(chRequestedFilePath);
data = textscan(fid,'%s');
fclose(fid);
c1chRequested = data{:};

chContourDir = 'D:\Users\sdammak\Data\LUSC\Original\Segmentations\CancerMC\Curated';
stContourPaths = dir([chContourDir,'\TCGA-*.qpdata']);
c1chContoured = {stContourPaths.name}';

% Make vector finding the position of the contoured samples in the requested list
dFoundIndices = nan(length(c1chContoured),1);

for iContouredSample = 1:length(c1chContoured)

    c1chIndexInRequested = strfind(c1chRequested, c1chContoured{iContouredSample});
    dIndexInRequested = find(not(cellfun('isempty',c1chIndexInRequested)));
    if isempty(dIndexInRequested)
        error('A slide that was not requested was contoured!')
    end
    
    dFoundIndices(iContouredSample) = dIndexInRequested;
end
dCleanIndices = dFoundIndices(~isnan(dFoundIndices));
c1chRequestedAndCompleted = c1chRequested(dCleanIndices);
c1chRequested(dCleanIndices) = [];

disp(['These slides were not in the Contoured folder:', newline, c1chRequested{:}])