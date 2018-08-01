clearvars; fclose all;
addpath('D:\code\DE_Detector-master\funs')
folderNameWild = 'F:\MC\GOM_MC_Metadata\MC06\GofMx_MC06*';
dirToProc = dir(folderNameWild);
tf_fname = 'D:\TFs\651_110817\651_110817_HARP.tf';

for iDir = 1:length(dirToProc)
    folderName = [fileparts(folderNameWild),'\',dirToProc(iDir).name];
    matList = dir([folderName,'\','*.mat']);
    
    f = [];
    for iF = 1:length(matList)
        % Determine the frequencies for which we need the transfer function
        if isempty(f)
            load(fullfile(folderName,matList(iF).name),'f') 
           
            [~, xfrOffsetRev] = dtf_map(tf_fname,f*1000);
        end

        load(fullfile(folderName,matList(iF).name),'specClickTf','clickTimes',...
            'hdr','ppSignal','yFiltBuff','p','xfrOffset') 
        xfrOffset = xfrOffset';
        if ~isempty(specClickTf)
            % Subtract old Tf and add new
            thisSpec_noTF = specClickTf- repmat(xfrOffset,size(specClickTf,1),1);
            specClickTfRev = thisSpec_noTF + repmat(xfrOffsetRev,size(specClickTf,1),1);
            
            [~,oldPeakFrIdx] = max(specClickTf,[],2);
            [~,peakFrIdx] = max(specClickTfRev,[],2);
            
            ppSig_noTF = ppSignal - xfrOffset(oldPeakFrIdx)';
            ppSignalNew = ppSig_noTF + xfrOffsetRev(peakFrIdx)';
                        
            keepers = ppSignalNew>= 0;
    
            specClickTf = specClickTfRev(keepers,:);
            clickTimes = clickTimes(keepers,:);
            ppSignal = ppSignalNew(keepers,:);
            yFiltBuff = yFiltBuff(keepers,:);
            
            
            % prune out low amplitude detections:

            % replace old tf in params struct with new.
            p.xfrOffset = xfrOffsetRev;
            p.tfName = tf_fname;
            save(fullfile(folderName,matList(iF).name),'specClickTf',...
                'clickTimes','hdr','ppSignal','yFiltBuff','p','f','-mat','-v7.3')
        end
        fprintf('done with file %d of %d \n',iF, length(matList))
    end
end