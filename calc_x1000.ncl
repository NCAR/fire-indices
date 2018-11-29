/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
 mc1000 is percent moisture content for 1000-hour timelag
 yx1000 is yesterday's x1000
 maxt is maximum daily temperature
 mint is minimum daily temperature
 hveg is the vegetation stage
;/
function calc_x1000(mc1000, ym1000, yx1000, maxt, mint, hveg)   ;x1000 is a variable in the herbaceous fuel model
local diff, kwet, tempcheck, ktemp, x1000
begin

diff = mc1000 - ym1000
kwet = where((mc1000 .gt. 25.), 1., .0333 * mc1000 + .1675)
;kwet = where(mc1000 .lt. 10., 0.5, kwet)       this only appears in the paper
tempcheck = (maxt + mint) / 2.
ktemp = where(tempcheck .le. 50., 0.6, 1.0)
x1000 = yx1000 + (diff * kwet * ktemp)
x1000 = where(hveg .eq. "pregreen" .or. hveg .eq. "frozen" .or. hveg .eq. "cured", mc1000, x1000)

return(x1000)

end

