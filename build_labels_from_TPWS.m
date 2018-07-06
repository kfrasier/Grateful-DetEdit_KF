clearvars

baseDir = 'I:\JAX13D_broad_metadata\TPWS_noMinPeakFr'; % directory containing de_detector output
siteName = 'JAX_D_13_disk'; % site name, used to name the output file
outDir = 'I:\JAX13D_broad_metadata\TPWS_noMinPeakFr\labels';

fMatch = fullfile(baseDir,[siteName,'*TPWS1.mat']);
fileSet = dir(fMatch);
lfs = length(fileSet);
for itr2 = 1:lfs
    thisFileTs = fileSet(itr2).name;
    thisFullFileTs = fullfile(fileSet(itr2).folder,thisFileTs);
    thisFilePred = strrep(thisFileTs,'TPWS1.mat','predLab.mat');
    thisFullFilePred = fullfile(outDir,thisFilePred);
    if exist(thisFullFilePred,'file')==2
        load(thisFullFilePred)
        load(thisFullFileTs,'MTT');
        predLabels = double(predLabels)';
        zID = [MTT,predLabels+5];
    end
    fprintf('done with file %0.0f of %0.0f\n',itr2,lfs)
    outName = strrep(thisFileTs,'TPWS1.mat','ID1.mat');
    save(fullfile(outDir,outName),'zID','-v7.3')
 
end


