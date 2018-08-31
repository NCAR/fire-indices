load "calc_daylight_manual.ncl"
load "calc_daylight_builtin.ncl"

/;
 tmmn is minimum daily temperature
 lat is latitude
 vpd is vapor pressure deficit
 day_year is the day of year
 lonlen is the number of longitude coordinates in the area of calculation
 gsi is growing season index
;/
function calc_gsi(tmmn, lat, vpd, day_year, lonlen)
local vpd1, day_year, daylit, dayl, tmmn1, gsi, gsi_avg, gsi_adj
begin

vpd1 = 1 - (vpd - .9) / 3.2                     ;note that the variables vpd1, dayl, and tmmn1 are all normalized in some way, could be consolidated to a general normalizing function (not to be confused with function normalize)
vpd1 = where(vpd .le. 0.9, 1., vpd1)
vpd1 = where(vpd .ge. 4.1, 0., vpd1)

daylit = calc_daylight_manual(day_year, lat, lonlen)

dayl = (daylit - 10.) / 11.
dayl = where(daylit .lt. 10, 0., dayl)
dayl = where(daylit .gt. 11, 1., dayl)

tmmn1 = (tmmn + 2) / 7.
tmmn1 = where(tmmn .ge. 5., 1, tmmn1)
tmmn1 = where(tmmn .le. -2., 0., tmmn1)

gsi = tmmn1 * vpd1 * dayl

timelen = dimsizes(gsi(:, 0,0))
latlen = dimsizes(gsi(0, :, 0))
gsi1 = conform_dims((/timelen + 20, latlen, lonlen/), flt2dble(0.), -1)	;pad gsi with 10 zeros on either end to avoid missing values in actual data when computing average
gsi1(10:(timelen+9), :, :) = gsi

gsi_avg = runave_n(gsi1, 21, 0, 0)

gsi_adj = gsi_avg(10:timelen+9, :, :)   ;discards the extra zeros on both ends of the array

return(gsi_adj)

end

