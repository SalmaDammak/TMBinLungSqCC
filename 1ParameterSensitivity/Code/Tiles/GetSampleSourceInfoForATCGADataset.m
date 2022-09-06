function [msAllInfo, vsFileNames, vsTSS, vsPatientIds] = GetSampleSourceInfoForATCGADataset(chDatasetDirectory)
% This function allows me to pull out the information on the TCGA-LUSC slides that I want to
% diversify whenever I want a subsample from the dataset

stWholeSlidePaths = dir([chDatasetDirectory,'\TCGA-*.svs']);

dNumSlides = length(stWholeSlidePaths);

vsTSS = strings(dNumSlides, 1);
vsPatientIds = strings(dNumSlides, 1);
vsFileNames = strings(dNumSlides, 1);


for i = 1:dNumSlides
    
    chFileName = stWholeSlidePaths(i).name;
    vsFileNames(i) = string(chFileName);
    
    vsAllElements = split(string(chFileName),'-');
    
    vsTSS(i) = vsAllElements(2);
    vsPatientIds(i) = join([vsAllElements(2),"-",vsAllElements(3)],'');    
end

msAllInfo =  [vsFileNames, vsTSS, vsPatientIds];

end