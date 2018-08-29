/;
warmdays is the number of (consecutive?) days where the maximum temperature is above freezing
colddays is the number of days where the minimum temperature below freezing
gdd is the growing degree days
maxt is the maximum temperature
mint is the minimum temperature
j_date is the day of year or julian day
j_green is the day of year on which greenup was initialized
gren is the fraction of the greenup period that has elapsed
mcherb is the calculated herbaceous percent moisture content
hveg is the vegetation stage
;/

function calc_vegstage(warmdays, colddays, gdd, maxt, mint, j_date, j_green, gren, mcherb, hveg)
local vegstage, prgrn_check
begin

vegstage = where(hveg .eq. "pregreen" .and. j_date .ge. j_green, "greenup", hveg)
vegstage = where(hveg .eq. "greenup" .and. gren .ge. 100. .and. mcherb .ge. 120., "green", vegstage)
vegstage = where(hveg .eq. "greenup" .and. gren .ge. 100. .and. mcherb .lt. 120., "transition", vegstage)
vegstage = where(hveg .eq. "green" .and. mcherb .lt. 120, "transition", vegstage)
vegstage = where(hveg .eq. "transition" .and. mcherb .le. 30., "cured", vegstage)
vegstage = where(colddays .ge. 3 .and. hveg .eq. "cured", "frozen", vegstage)

return(vegstage)

end


