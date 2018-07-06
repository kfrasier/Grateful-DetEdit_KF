% mkTPWS_perDir.m

% Script takes output from de_detector.m and put it into a format for use in
% detEdit.
% Output:
% A TPWS.m file containing 4 variables:
%   MTT: An Nx2 vector of detection start and end times, where N is the
%   number of detections
%   MPP: An Nx1 vector of recieved level (RL) amplitudes.
%   MSP: An NxF vector of detection spectra, where F is dictated by the
%   parameters of the fft used to generate the spectra and any
%   normalization preferences.
%   f = An Fx1 frequency vector associated with MSP

clearvars

% Setup variables:
baseDir = 'I:\JAX13D_broad_metadata'; % directory containing de_detector output
outDir = 'I:\JAX13D_broad_metadata\TPWS_116'; % directory where you want to save your TPWS file
siteName = 'JAX_D_13'; % site name, used to name the output file
ppThresh = 116; % minimum RL in dBpp. If detections have RL below this
% threshold, they will be excluded from the output file. Useful if you have
% an unmanageable number of detections.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check if the output file exists, if not, make it
if ~exist(outDir,'dir')
    fprintf('Creating output directory %s\n',outDir)
    mkdir(outDir)
end
letterCode = 97:122;
dirSet = dir(fullfile(baseDir,[siteName,'*']));
maxRows = 1800000;
tsWin = 300;
fs = 200000;
for itr0 = 3:length(dirSet)
    fSave = [];
    if dirSet(itr0).isdir &&~strcmp(dirSet(itr0).name,'.')&&...
            ~strcmp(dirSet(itr0).name,'..')
        
        letterFlag = 0; % flag for knowing if a letter should be appended to disk name
        inDir = fullfile(baseDir,dirSet(itr0).name);
        fileSet = what(inDir);
        lfs = length(fileSet.mat);
        clickTimesVec = zeros(maxRows,1);
        clickTimesMax = zeros(maxRows,1);
        ppSignalVec = zeros(maxRows,1);
        tsVecStore = zeros(maxRows,tsWin);
        specClickTfVec = zeros(maxRows,191);
        subTP = 1;
        rowCounter = 1;
        
        for itr2 = 1:lfs
            thisFile = fileSet.mat(itr2);
            
            load(char(fullfile(inDir,thisFile)),'-mat','clickTimes','hdr','peakFr',...
                'ppSignal','specClickTf','yFiltBuff','f','durClick')
            if ~isempty(clickTimes)&& size(specClickTf,2)>1
                % specClickTf = specClickTfHR;
                keepers = find(ppSignal >= ppThresh);
                % keepersB = find(peakFr > 6);
                % keepers = intersect(keepersA, keepersB);
                ppSignal = ppSignal(keepers);
                clickTimes = clickTimes(keepers,:);
                
                [~,keepers2] = unique(clickTimes(:,1));
                
                clickTimes = clickTimes(keepers2,:);
                ppSignal = ppSignal(keepers2);
                
                fileStart = datenum(hdr.start.dvec);
                posDnum = (clickTimes(:,1)/(60*60*24)) + fileStart +...
                    datenum([2000,0,0,0,0,0]);
                
                nRows = length(ppSignal);
                tsCell = {yFiltBuff{keepers(keepers2)}}';
                % check for really long ones and truncate
                tooLong = find((cellfun(@(x)length(x),tsCell))>tsWin);
                for iTL = 1:length(tooLong)
                    tsCell{tooLong(iTL)} = tsCell{tooLong(iTL)}(1:tsWin);
                end
                outVar = cellfun(@(x)cat(2,x,zeros(1,tsWin-length(x))),tsCell,'UniformOutput',false);
                
                tsVec = cell2mat(outVar);
                [~,maxIdx] = max(tsVec,[],2);
                tsVecStore(rowCounter:rowCounter+nRows-1,:) = tsVec;
                
                clickTimesVec(rowCounter:rowCounter+nRows-1,1) = posDnum;
                clickTimesMax(rowCounter:rowCounter+nRows-1,1) = posDnum+((maxIdx./fs)/(24*60*60));
                
                ppSignalVec(rowCounter:rowCounter+nRows-1,1) = ppSignal;
                specClickTfVec(rowCounter:rowCounter+nRows-1,:) = specClickTf(keepers(keepers2),:);
                
                tsVecStore(rowCounter:rowCounter+nRows-1,:) = tsVec;
                
                
                % want to align clicks by max cycle
                % f = fHR;
                if isempty(fSave)
                    fSave = f;
                end
                
                
                %                 if iscell(specClickTf)
                %                     spv = cell2mat(specClickTf');
                %                     specClickTfVec = [specClickTfVec; spv(:,keepers(keepers2))'];
                %                 else
                %                     specClickTfVec = [specClickTfVec; specClickTf(keepers(keepers2),:)];
                %                 end
                clickTimes = [];
                hdr = [];
                specClickTf = [];
                ppSignal = [];
                rowCounter = rowCounter+nRows;

            end
            fprintf('Done with file %d of %d \n',itr2,lfs)
            
            if (rowCounter>= maxRows && (lfs-itr2>=10))|| itr2 == lfs
                  keepRows = ppSignalVec>0;
                MSN = tsVecStore(keepRows,:);
                MTT = clickTimesVec(keepRows);
                MTTmax = clickTimesMax(keepRows);
                MPP = ppSignalVec(keepRows);
                MSP = specClickTfVec(keepRows);
                if itr2 == lfs && letterFlag == 0
                    ttppOutName =  [fullfile(outDir,dirSet(itr0).name),'_TPWS1','.mat'];
                    fprintf('Done with directory %d of %d \n',itr0,length(dirSet))
                    subTP = 1;
                else
                    ttppOutName = [fullfile(outDir,dirSet(itr0).name),char(letterCode(subTP)),'_TPWS1','.mat'];
                    fprintf('Saving intermediate file %s,', ttppOutName)
                    subTP = subTP+1;
                    letterFlag = 1;
                end
                f = fSave;
                save(ttppOutName,'MTT','MPP','MSP','MSN','MTTmax','f','-v7.3')
                
                MTT = [];
                MPP = [];
                MSP = [];
                MSN = [];
                MTTmax=[];
                rowCounter = 1;

                clickTimesVec = [];
                ppSignalVec = [];
                specClickTfVec = [];
                tsVecStore = [];
                clickTimesMax = [];
            end
        end
    end
end

