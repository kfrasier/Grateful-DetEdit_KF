baseDir = 'I:\JAX13D_broad_metadata'; % directory containing de_detector output
siteName = 'JAX_D_13'; % site name, used to name the output file

tsWin = 300;
dirSet = dir(fullfile(baseDir,[siteName,'*']));

for itr0 = 2%1:length(dirSet)
    if dirSet(itr0).isdir &&~strcmp(dirSet(itr0).name,'.')&&...
            ~strcmp(dirSet(itr0).name,'..')
        inDir = fullfile(baseDir,dirSet(itr0).name);
        fileSet = what(inDir);
        lfs = length(fileSet.mat);
        
        for itr2 = 1:lfs
            thisFile = fileSet.mat(itr2);
            
            load(char(fullfile(inDir,thisFile)),'-mat','yFiltBuff')
            % check for really long ones and truncate
            tooLong = find((cellfun(@(x)length(x),yFiltBuff))>tsWin);
            for iTL = 1:length(tooLong)
                yFiltBuff{tooLong(iTL)} = yFiltBuff{tooLong(iTL)}(1:tsWin);
            end
            outVar = cellfun(@(x)cat(2,x,zeros(1,tsWin-length(x))),yFiltBuff,'UniformOutput',false);
            
            tsMat = cell2mat(outVar);
            outFileName = fullfile(inDir,strrep(thisFile,'.mat','_tsMat.mat'));
            save(outFileName{1}, 'tsMat','-v7.3')
        end
    end
    fprintf('Done with folder %0.0f of %0.0f\n',itr0,length(dirSet))
end