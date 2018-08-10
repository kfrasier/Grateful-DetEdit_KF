function [brushDate, brushColor] = get_brushed(hFig)


brushDate = [];
brushColor = [];

hBrush = findall(hFig,'tag','Brushing');

% get x info from brushed data
brushDataX = get(hBrush, {'Xdata'});
% don't understand why nan values appear, create index of valid points here
if ~isempty(brushDataX)
    brushID = ~isnan(brushDataX{1,1});
    
    % get color info
    brushColor = get(hBrush, {'Color'});
    brushColor = round(brushColor{1,1}.*100)./100;
    % get vector of dates associated with these points
    markerDates = get(findall(hFig),'UserData');
    filledMarkers = markerDates(~cellfun('isempty',markerDates));
    brushDate = filledMarkers{end}(brushID);
end