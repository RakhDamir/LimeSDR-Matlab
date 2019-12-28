function timeline = currTimeLine()
% returns current time in specific format
    timeline = datestr(datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss'));