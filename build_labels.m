baseDir = 'I:\JAX13D_broad_metadata'; % directory containing de_detector output
outDir = 'I:\JAX13D_broad_metadata\TPWS_116'; % directory where you want to save your TPWS file
siteName = 'JAX_D_13_disk'; % site name, used to name the output file

tsWin = 300;
dirSet = dir(fullfile(baseDir,[siteName,'*']));

for itr0 = 1:length(dirSet)
    if dirSet(itr0).isdir &&~strcmp(dirSet(itr0).name,'.')&&...
            ~strcmp(dirSet(itr0).name,'..')
        zID = [];
        fMatch = fullfile(baseDir,[dirSet(itr0).name,'\*tsMat.mat']);
        fileSet = dir(fMatch);
        lfs = length(fileSet);
        for itr2 = 1:lfs
            thisFullFileTs = fullfile(fileSet(itr2).folder,fileSet(itr2).name);
            thisFullFilePred = strrep(thisFullFileTs,'tsMat.mat','predLab.mat');
            if exist(thisFullFilePred,'file')==2
                load(thisFullFilePred)
                load(strrep(thisFullFileTs,'_tsMat.mat','.mat'),...
                    'ppSignal','clickTimes','hdr');
                predLabels = double(predLabels);
                keepSignal = ppSignal>120;
                fileStart = datenum(hdr.start.dvec);
                posDnum = (clickTimes(:,1)/(60*60*24)) + fileStart +...
                    datenum([2000,0,0,0,0,0]);
                zID = [zID;[posDnum(keepSignal),predLabels(keepSignal)']];
            end
            fprintf('done with file %0.0f of %0.0f\n',itr2,lfs)
        end
    end
    save(fullfile(baseDir,[dirSet(itr0).name,'_allLabels_ID1.mat']),'zID','-v7.3')
end

