/;
 rad is solar radiation
 ppt is hourly precipitation amount in inches/hr (sum of all precip over 24 hrs) / (24 hrs)
 maxrad is clear sky radiation
 sow are State of Weather Codes
;/

function calc_sow_daily(rad, ppt, maxrad)
local sow, percent_cloud
begin

;maxrad1 = conform(rad, maxrad, 0)
percent_cloud = rad / maxrad

sow = ppt
sow = -1

sow = where(percent_cloud .ge. 0.91, 0, sow)
sow = where(percent_cloud .lt. 0.91, 1, sow)
sow = where(percent_cloud .lt. 0.73, 2, sow)
sow = where(percent_cloud .lt. 0.5, 3, sow)
sow = where(ppt .ge. .01, 5, sow)       ; to indicate recent precipitation
sow = where(ppt .ge. .05, 6, sow)

return(sow)

end

