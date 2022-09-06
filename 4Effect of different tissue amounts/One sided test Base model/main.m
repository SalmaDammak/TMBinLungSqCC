% all quoted text is from: https://www.mathworks.com/help/stats/ranksum.html#bti4qfq-h

load(Experiment.GetDataPath('TissueAmounts'));

x = vdCorrectlyClassifiedPatientsTissueArea;
y = vdIncorrectlyClassifiedPatientsTissueArea;

% % Ho: both median are equal
%"'right'	Right-tailed hypothesis test, where the alternative
%hypothesis states that the median of x is greater than the median of y."
% i.e. Ha: median of vdCorrectlyClassifiedPatientsTissueArea > vdIncorrectlyClassifiedPatientsTissueArea

[dPValue, bHoRejected, stOtherTestInfo] = ranksum(x,y,'alpha',0.05,'tail','right');

% "If h = 1, this indicates rejection of the null hypothesis at the 100 *
% alpha% significance level."
if bHoRejected
    sResult = "rejcted";
else
    sResult = "NOT rejcted";
end

disp("Ho: median tissue of correctly classified patients = median of incorrectly classified patients")
disp("Ha: median tissue of correctly classified patients > median of incorrectly classified patients")
disp("The null hypothsis is " + sResult)
disp("with p-value: " + num2str(dPValue))


save([Experiment.GetResultsDirectory(),'\Workspace.mat']);