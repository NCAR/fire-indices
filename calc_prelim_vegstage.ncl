/;
2018, Copyright University Corporation for Atmospheric Research
;/


/;
 hveg is the vegetation stage
 warmdays is the number of consecutive days above freezing
 colddays is the number of days below freezing
 j_date is day of year
 j_green is the day to signal greenup
 gdd is growing degree days
;/
function calc_prelim_vegstage(hveg, warmdays, colddays, j_date, j_green, gdd)
local vegstage, vegstage1
begin

if(j_date .eq. 1) then
        vegstage1 = "pregreen"
else
        vegstage1 = hveg
end if

vegstage = where(vegstage1 .eq. "pregreen" .and. j_date .ge. 60. .and. j_date .le. 212 .and. warmdays .gt. 5 .and. gdd .gt. 300, "greenup", vegstage1)
vegstage = where(vegstage1 .eq. "cured" .and. colddays .ge. 3, "frozen", vegstage)

return(vegstage)

end

