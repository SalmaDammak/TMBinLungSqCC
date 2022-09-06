function DeleteFilesWithRegexp(chRegularExpression)
stFileInfo = dir(chRegularExpression);

for i = 1:length(stFileInfo)
    delete([stFileInfo(i).folder,'\', stFileInfo(i).name])
end

end