
baseDir =  'H:\MC\GOM_MC_LTSA';
dirList = dir('H:\MC\GOM_MC_LTSA\M*');
%deplpwr = {};
for iDir =7%8:length(dirList)
    fList = dir(fullfile(baseDir,dirList(iDir).name,'*.ltsa'));
    mPwr = [];

    for iFile = 5:length(fList)
        thisFile =  fullfile(baseDir,dirList(iDir).name,fList(iFile).name);
        hdr = ioReadLTSAHeader(thisFile);

        fid = fopen(thisFile,'r');
        skip = hdr.ltsa.byteloc(1);
        fseek(fid,skip,-1);
        pwrmean = zeros(1001,1);
        for iBin = 1:length(hdr.ltsa.nave)
            pwr = fread(fid,[hdr.ltsa.nf,hdr.ltsa.nave(iBin)],'int8');
            if ~isempty(pwr)
                pwrmean = pwrmean+mean(pwr,2);
            end
        end
        mPwr(iFile,:) = pwrmean./length(hdr.ltsa.nave);
        fclose(fid);
        fprintf('Done with file %0.0f folder %0.0f\n',iFile,iDir)
    end
    deplpwr{iDir,1} = mPwr;
end

for itrP = 1:size(deplpwr,1)
    meanDeplPwr(itrP,:) = smooth(mean(deplpwr{itrP}));
end