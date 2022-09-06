function [vsSlides,dNumUniqueTSS, dNumUniquePatients,vsUniquePatientIDs, vsUniqueTSS,...
    vsPatientIDs, vsTSS] = GetSlideInformationFromSlideNamesTextFile(chTextFileLocation)

chSlides = strtrim(fileread(chTextFileLocation));
c1chSlides = strsplit(chSlides,'\n');
vsSlides = string(c1chSlides);

vsPatientIDs = string(cellfun(@(s) s(1:12), c1chSlides, 'UniformOutput', false));
vsUniquePatientIDs = unique(vsPatientIDs);
dNumUniquePatients = length(vsUniquePatientIDs);

vsTSS = string(cellfun(@(s) s(1:7), c1chSlides, 'UniformOutput', false));
vsUniqueTSS = unique(vsTSS);
dNumUniqueTSS = length(vsUniqueTSS);


end