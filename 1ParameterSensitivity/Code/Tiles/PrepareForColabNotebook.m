function PrepareForColabNotebook(chTileAndMaskInputDir, chTileAndMaskOutputDir)

% Get all label paths
stMaskPaths = dir([chTileAndMaskInputDir,'\TCGA-*(*)-labels.png']);

mkdir(chTileAndMaskOutputDir)
mkdir([chTileAndMaskOutputDir,'\labels'])
mkdir([chTileAndMaskOutputDir,'\images'])

vsRealNameToNumberMapping = [];

for i = 1 : length(stMaskPaths)
    
    chMaskSourcePath = [chTileAndMaskInputDir,'\' stMaskPaths(i).name];
    chTileSourcePath = strrep(chMaskSourcePath,'-labels','');
    
    % Rename using sequential numbers
    chMaskDestinationPath = [chTileAndMaskOutputDir,'\labels\',num2str(i),'.png'];
    chTileDestinationPath = [chTileAndMaskOutputDir,'\images\',num2str(i),'.png'];
    
    copyfile(chMaskSourcePath, chMaskDestinationPath)
    copyfile(chTileSourcePath, chTileDestinationPath)   
    
    vsRealNameToNumberMapping = [string(vsRealNameToNumberMapping);string([num2str(i),'-',stMaskPaths(i).name])];
end
   
save('RealNameToNumberMapping.mat','vsRealNameToNumberMapping')
end