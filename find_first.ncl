/;
 gsix is normalized GSI, or growing season index
 j_date is the day of year
 latlen is the number of latitude marks
 lonlen is the number of longitude marks
;/
function find_first(gsix, j_date, latlen, lonlen)               ;replaces the line < greenup(i)=find(gsix(:,i)>.5,1,'first') > in MATLAB
local ndays_year, nyears, jan1, cut_gsi, start_ind, end_ind, gsi_year, j_green
begin

ndays_yr = 365.2425
nyears = tointeger(ceil(dimsizes(j_date) / ndays_yr))
jan1 = dim_minind(j_date, 0)    ;the index of first occurence of January 1st

cut_gsi = where(gsix .ge. .5, .5, gsix) ;it does not matter if it goes higher than 0.5, so cut it off here to use a find maximum function

j_green = conform_dims((/nyears, latlen, lonlen/), 0, -1)

do i = 0, nyears-1
        start_ind = tointeger(jan1 + i*ndays_yr) < (dimsizes(cut_gsi(:, 0, 0))-1)
        end_ind = tointeger(jan1 + (i + 1) * ndays_yr) < (dimsizes(cut_gsi(:, 0, 0))-1)
        gsi_year = cut_gsi(start_ind:end_ind, :, :)             ;partition full run into year-long chunks
        j_green(i, :, :) = dim_maxind(gsi_year, 0)      ;find the first instance of 0.5 in the year. This should initialize greenup. assumes .5 is always reached, but if not will return whatever the highest gsi value is
        delete(gsi_year)
end do

return(j_green)

end

