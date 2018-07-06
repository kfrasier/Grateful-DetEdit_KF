
% itr_mkLTSA.m
% Iterates over a directory of TPWS files and calls mkLTSAsessions for each
% one.

clearvars
%clear global
filePrefix = 'HAT_A_06'; % File name to match. 
% File prefix should include deployment, site, (disk is optional). 
% Example: 
% File name 'GofMX_DT01_disk01-08_TPWS2.mat' 
%                    -> filePrefix = 'GofMX_DT01'
% or                 -> filePrefix ='GOM_DT_09' (for files names with GOM)
sp = ''; % your species code
itnum = '1'; % which iteration you are looking for
srate = 200; % sample rate
LTSApath = 'F:\HAT_A_06\HAT_A_06_LTSA'; % directory containing all LTSAs for this deployment
% LTSA folder should match the site specified in prefix
tpwsPath = 'F:\HAT_A_06\HAT_A_06_d1-3_TPWS'; %directory of TPWS files
%tfName = 'E:\TF_files'; % Directory ...
% with .tf files (directory containing folders with different series ...



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

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

% for each TPWS file found, make LTSA.mat file
for iD = 5:length(fileMatchIdx);
    matchingFile = fileList{fileMatchIdx(iD)};
    detfn = dir(fullfile(tpwsPath,matchingFile));
    
    mkLTSAsessions('filePrefix', filePrefix, 'detfn',detfn.name,...
       'sp', sp, 'lpn', LTSApath, 'sdir', tpwsPath,'srate',srate)
end