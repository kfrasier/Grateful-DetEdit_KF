function [KB,binCX,binT,binC] = ndets_per_bin(t,xt,y,dt,minNdet,nd)
% Calculate the number detection per bin
% moved into subroutine kf 9/30/2016

dur = t(end) - t(1);    % session duration
% sort detections into time bins, get max RL for time bin
binDur = 5;     % bin duration [minutes] use 5 for density est
nbin = ceil(dur*24*60/binDur);
% interDetection Interval threshold
dtTH = 1 ;  % [seconds] 1
bin = 1;
kb = 1;
RL = zeros(nbin,1);
C = zeros(nbin,1);  CX = zeros(nbin,1);
T = zeros(nbin,1);
Ndt = zeros(nbin,1);
mdt = zeros(nbin,1);
while kb <= nd
    % while kb <= nbin
    tv = datevec(t(kb));     % put time(kb)in vector format
    tbin = floor(tv(5)/binDur);  % define time bin of time(kb)
    t0 = datenum([tv(1:4) tbin*binDur 00]); % lower bound
    t1 = datenum([tv(1:4) (tbin+1)*binDur 00]); % upper bound
    I = [];  IX = [];   % index for times in time bin
    I = find(t >= t0 & t < t1);  % find times in bin
    IX = find(xt >= t0 & xt < t1);  % find test times in bin
    if ~isempty(I)
        C(bin) = length(I); % the number of detections in time bin
        CX(bin) = length(IX); % the number of test detect in time bin
        RL(bin) = max(y(I));    % max RL in time bin
        T(bin) = t0;        % time for time bin
        if I > 1
            L = find(dt(I-1) < dtTH);
            if ~isempty(L)
                Ndt(bin) = length(L);
                % number of InterDetection Interval under threshold
                mdt(bin) = mean(dt(I(L)-1));
            end
        end
        kb = I(end) + 1;      % set loop index to next time
        bin = bin + 1;  % increment bin number
    else
        if t(kb) == 0
            kb = kb + 1;
            bin = bin+1;
        else
            disp('this should not be possible')
            return
        end
    end
end
KB = [];  KBX = [];
KB = find(C >= minNdet);
KBX = find(CX >= minNdet);

binT = T(KB) + datenum([0 0 0 0 binDur/2 0]);
binRL = RL(KB);
binC = C(KB);
binCX = CX(KBX);
