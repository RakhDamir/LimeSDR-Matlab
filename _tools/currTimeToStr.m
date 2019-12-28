function timestring = currTimeToStr()
    currdate    = datestr(now,'mm-dd-yy--HH-MM-SS');
    t           = datetime('now','Format','y-MMM-d_HH_mm_ss');
    formatOut   = 'yyyy-mm-dd_HHMMSS';
    timestring  = datestr(t,formatOut);