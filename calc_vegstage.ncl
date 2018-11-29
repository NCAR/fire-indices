/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
colddays is the number of days where the minimum temperature below freezing
maxt is the maximum temperature
mint is the minimum temperature
j_date is the day of year or julian day
j_green is the day of year on which greenup was initialized
gren is the fraction of the greenup period that has elapsed
mcherb is the calculated herbaceous percent moisture content
hveg is the vegetation stage
;/

function calc_vegstage(colddays, maxt, mint, j_date, j_green, gren, mcherb, hveg)
local vegstage, prgrn_check
begin

if(j_date .eq. 1) then
        vegstage1 = "pregreen"
else
        vegstage1 = hveg
end if

vegstage = where(hveg .eq. "pregreen" .and. j_date .ge. j_green, "greenup", hveg)
vegstage = where(hveg .eq. "greenup" .and. gren .ge. 100. .and. mcherb .ge. 120., "green", vegstage)
vegstage = where(hveg .eq. "greenup" .and. gren .ge. 100. .and. mcherb .lt. 120., "transition", vegstage)
vegstage = where(hveg .eq. "green" .and. mcherb .lt. 120, "transition", vegstage)
vegstage = where(hveg .eq. "transition" .and. mcherb .le. 30., "cured", vegstage)
vegstage = where(hveg .eq. "cured" .and. colddays .ge. 3, "frozen", vegstage)

return(vegstage)

end


