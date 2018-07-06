load('E:\bigDL\CANARC_PI_01_AllWarp_AllSp.mat')
for iPlot =1:190
    figure(1);clf
    subplot(2,1,1)
    plot(d.origFeats{iPlot})
    subplot(2,1,2)
    plot(d.mfeats{iPlot}(:,1))
end