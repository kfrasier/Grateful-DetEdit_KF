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
baseDir = 'F:\HAT_A_06\HAT_A_06_d1-3\Dolphins'; % directory containing de_detector output
outDir = 'F:\HAT_A_06\HAT_A_06_d1-3_TPWS'; % directory where you want to save your TPWS file
siteName = 'HAT_A_06'; % site name, used to name the output file
ppThresh = 120; % minimum RL in dBpp. If detections have RL below this
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

maxRows = 1500000;
for itr0 = 1%:length(dirSet)
    fSave = [];
    if dirSet(itr0).isdir &&~strcmp(dirSet(itr0).name,'.')&&...
            ~strcmp(dirSet(itr0).name,'..')
        
        letterFlag = 0; % flag for knowing if a letter should be appended to disk name
        inDir = fullfile(baseDir,dirSet(itr0).name);
        fileSet = what(inDir);
        lfs = length(fileSet.mat);
        clickTimesVec = zeros(maxRows,1);
        ppSignalVec = zeros(maxRows,1);
        specClickTfVec = zeros(maxRows,191);
        tsVecStore =zeros(maxRows,300);
        subTP = 1;
        matIdxStart = 1;
        for itr2 = 1:lfs
            thisFile = fileSet.mat(itr2);
            
            load(char(fullfile(inDir,thisFile)),'-mat','clickTimes','hdr',...
                'ppSignal','yFiltBuff','f','p','specClickTf')
            if ~isempty(f)
                fOld = f;
            end
            
            p.frameLengthUs = 2000;
            p.fftSize = ceil(hdr.fs * p.frameLengthUs / 1E6);
            if rem(p.fftSize, 2) == 1
                p.fftSize = p.fftSize - 1;  % Avoid odd length of fft
            end
            
            p.fftWindow = hann(p.fftSize)';
            N = length(p.fftWindow);
            f = 0:((hdr.fs/2)/1000)/((N/2)):((hdr.fs/2)/1000);
            
            lowSpecIdx = round(5000/hdr.fs*p.fftSize);
            highSpecIdx = round(100000/hdr.fs*p.fftSize);
            specRangeOld =  p.specRange;
            p.specRange = lowSpecIdx:highSpecIdx;
            p.binWidth_Hz = hdr.fs / p.fftSize;
            f = f(p.specRange);
            p.xfrOffset = interp1(fOld,p.xfrOffset,f);

            % account for bin width
            sub = 10*log10(hdr.fs/N);
            
            specClickTfOld = specClickTf;
            specClickTf = [];
            if ~isempty(clickTimes)&& size(yFiltBuff,1)>1
                % specClickTf = specClickTfHR;
                [~,maxIdx] = max(specClickTfOld,[],2);
                peakFr = fOld(maxIdx);
                keepers = find(ppSignal >= ppThresh);
                nKeepers = length(keepers);
                % keepersB = find(peakFr > 12);
                % keepers = intersect(keepersA, keepersB);
                ppSignal = ppSignal(keepers);
                clickTimes = clickTimes(keepers,:);
                
%                 [~,keepers2] = unique(clickTimes(:,1));
%                 
%                 clickTimes = clickTimes(keepers2,:);
%                 ppSignal = ppSignal(keepers2);
                
                fileStart = datenum(hdr.start.dvec);
                posDnum = (clickTimes(:,1)/(60*60*24)) + fileStart +...
                    datenum([2000,0,0,0,0,0]);
                matIdxEnd = matIdxStart+nKeepers-1;
                
                if matIdxEnd> size(clickTimesVec,1)
                    disp('Have to add more rows')
                    % have to add more rows
                    clickTimesVec = [clickTimesVec;...
                        zeros(matIdxEnd-size(clickTimesVec,1),size(clickTimesVec,2))];
                    ppSignalVec = [ppSignalVec;...
                        zeros(matIdxEnd-size(ppSignalVec,1),size(ppSignalVec,2))];
                    tsVecStore = [tsVecStore;...
                        zeros(matIdxEnd-size(tsVecStore,1),size(tsVecStore,2))];
                    specClickTfVec = [specClickTfVec;...
                        zeros(matIdxEnd-size(specClickTfVec,1),size(specClickTfVec,2))];
                    
                end
                clickTimesVec(matIdxStart:matIdxEnd,1) = posDnum;
                ppSignalVec(matIdxStart:matIdxEnd,1) = ppSignal;
                tsWin = 300;
                tsVec = zeros(length(keepers),tsWin);
                
                specClickTf = zeros(nKeepers,length(f));
                for iTS = 1:nKeepers%(keepers2))
                    thisClick = yFiltBuff{keepers(iTS)}; %keepers2(iTS))};
                    winLength = length(thisClick);
                    wind = hann(winLength);
                    
                    wClick = zeros(1,N);
                    wClick(1:winLength) = thisClick.*wind.';
                    spClick = 20*log10(abs(fft(wClick,N)));
                    
                    spClickSub = spClick-sub;
                    
                    %reduce data to first half of spectra
                    spClickSub = spClickSub(:,1:N/2);
                    specClickTf(iTS,1:size(f,2)) = spClickSub(p.specRange) + p.xfrOffset;
                    
                    [~,maxIdx] = max(thisClick);
                    % want to align clicks by max cycle
                    % f = fHR;
                    if isempty(fSave)
                        fSave = f;
                    end
                    dTs = (tsWin/2) - maxIdx; % which is bigger, the time series or the window?
                    dTe =  (tsWin/2)- (length(thisClick)-maxIdx); % is the length after the peak bigger than the window?
                    if dTs<=0 % if the signal starts more than N samples ahead of the peak
                        % the start position in the TS vector has to be 1
                        posStart = 1;
                        % the start of the click ts has to be peak - 1/N
                        sigStart = maxIdx - (tsWin/2)+1;
                    else
                        % if it's smaller
                        posStart = dTs+1; % the start has to make up the difference
                        sigStart = 1; % and use the first index of the signal
                    end
                    
                    if dTe<=0 % if it ends after the cut off of N samples
                        posEnd = tsWin; % the end in the TS vector has to be at N
                        sigEnd = maxIdx + (tsWin/2); % and last index is N/2 points after the peak.
                    else % if it ends before the end of the TS vector
                        posEnd = tsWin-dTe; % the end point has to be the
                        % difference between the window length and the click length
                        sigEnd = length(thisClick);
                    end
                    
                    tsVec(iTS,posStart:posEnd) = thisClick(sigStart:sigEnd);
                end
                
                tsVecStore(matIdxStart:matIdxEnd,:) = tsVec;
                specClickTfVec(matIdxStart:(matIdxEnd),:) = specClickTf;
                matIdxStart = matIdxEnd + 1;
                clickTimes = [];
                hdr = [];
                specClickTf = [];
                ppSignal = [];
            end
            fprintf('Done with file %d of %d \n',itr2,lfs)
            
            if (matIdxEnd>= maxRows && (lfs-itr2>=10))|| itr2 == lfs
                dataRows = clickTimesVec>0;
                MSN = tsVecStore(dataRows,:);
                MTT = clickTimesVec(dataRows,:);
                MPP = ppSignalVec(dataRows,:);
                MSP = specClickTfVec(dataRows,:);
                if itr2 == lfs && letterFlag == 0
                    ttppOutName =  [fullfile(outDir,dirSet(itr0).name),'_Delphin_TPWS1','.mat'];
                    fprintf('Done with directory %d of %d \n',itr0,length(dirSet))
                    subTP = 1;
                else
                    
                    ttppOutName = [fullfile(outDir,dirSet(itr0).name),char(letterCode(subTP)),'_Delphin_TPWS1','.mat'];
                    subTP = subTP+1;
                    letterFlag = 1;
                end
                f = fSave;
                save(ttppOutName,'MTT','MPP','MSP','MSN','f','-v7.3')
                
                MTT = [];
                MPP = [];
                MSP = [];
                MSN = [];
                
                clickTimesVec = zeros(maxRows,1);
                ppSignalVec = zeros(maxRows,1);
                specClickTfVec = zeros(maxRows,191);
                tsVecStore =zeros(maxRows,300);
                matIdxStart=1;
            end
        end
    end
end
    
