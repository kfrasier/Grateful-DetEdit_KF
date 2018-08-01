% itr_modDet
% Iterates over a directory of TPWS files and calls modDet for each
% one.

clearvars
clear global
filePrefix = 'GofMX_MC02'; % File name to match. 
% File prefix should include deployment, site, (disk is optional). 
% Example: 
% File name 'GofMX_DT01_disk01-08_TPWS2.mat' 
%                    -> filePrefix = 'GofMX_DT01'
% or                 -> filePrefix ='GOM_DT_09' (for files names with GOM)
sp = 'Pm'; % your species code
itnum = '1'; % which iteration you are looking for
getParams = 'none'; % Calculate Parameterss: 
%                   -> 'none' do NOT compute parameters
%                   -> 'ici&pp' only to compute peak-to-peak, ici and
%                   peakFr
%                   -> 'all' compute pp, ici, 3/10dbBw, peakFr, F0, rms, dur
excludeID = 1; % yes - 1 | no - 0. Exclude ID times from MTT files 
srate = 200; % sample rate
gth = .5;  % gap time in hrs between sessions
tpwsPath = 'E:\TPWS'; %directory of TPWS files
%tfName = 'E:\transfer_functions'; % Directory ...
% with .tf files (directory containing folders with different series ...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% define subfolder that fit specified iteration
if itnum > 1
   for id = 2: str2num(itnum); % iternate id times according to itnum
       subfolder = ['TPWS',num2str(id)];
       tpwsPath = (fullfile(tpwsPath,subfolder));
   end
end

% Find all TPWS files that fit your specifications (does not look in subdirectories)
% Concatenate parts of file name
if isempty(sp)
    detfn = [filePrefix,'.*','TPWS',itnum,'.mat'];
else
    detfn = [filePrefix,'.*',sp,'.*TPWS',itnum,'.mat'];
end
% Get a list of all the files in the start directory
fileList = cellstr(ls(tpwsPath));
% Find the file name that matches the filePrefix
fileMatchIdx = find(~cellfun(@isempty,regexp(fileList,detfn))>0);
if isempty(fileMatchIdx)
    % if no matches, throw error
    error('No files matching filePrefix found!')
end

% for each TPWS file found, make TPWS(itnum+1).mat file
for iD = 1:length(fileMatchIdx);
    matchingFile = fileList{fileMatchIdx(iD)};
    detfn = dir(fullfile(tpwsPath,matchingFile));
    
    if exist('tfName','var')
    modDet('filePrefix', filePrefix, 'detfn',detfn.name,...
       'sp', sp, 'sdir', tpwsPath,'srate',srate,'itnum', itnum,...
       'getParams',getParams,'tfName',tfName,'excludeID',excludeID)
    else
        modDet('filePrefix', filePrefix, 'detfn',detfn.name,...
            'sp', sp, 'sdir', tpwsPath,'srate',srate,'itnum', itnum,...
            'getParams',getParams,'excludeID',excludeID)
    end
end
close all
disp('Done processing')