/;
2018, Copyright University Corporation for Atmospheric Research
;/

;load "crop.ncl"		;for use when paths are not set up correctly (the quick and dirty fix)
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/crop.ncl"	;for use in any other situation, aka the proper way


;Fo is the previous day's FFMC
;H is average relative humidity
;T is average temperature in Celsius
;W is wind speed in mph
;ro is daily rainfall, unadjusted

function calc_ffmc(Fo, H, T, W, ro)		;FFMC is Fine Fuel Moisture Content
local mo, mr, rf, Ed, Ew, ko1, kdw, m, F
begin

mo = 147.2 * (101. - Fo) / (59.5 + Fo)
rf = where(ro .gt. .5, ro - .5, -1.)
;following line tests if there was precipitation, then modify mo to account for precip. There are also 2 options for what modification needs to be made, hence the nested where statements
mo = where(rf .gt. 0., where(mo .gt. 150., mo + 42.5 * rf * exp(-100./(251.-mo)) * (1- exp(-6.93 / rf)) + .0015 * ((mo - 150.)^2) * sqrt(rf), mo + 42.5* rf * exp(-100./(251.-mo)) * (1 - exp(-6.93/rf))), mo)

Ed = .942 * H^0.679 + 11 * exp((H - 100.)/10.) + 0.18 * (21.1 - T) * (1 - exp(-.115 * H))
Ew = .618 * H^.753 + 10 * exp((H-100.)/10.) + 0.18 * (21.1 - T) * (1 - exp(-.115 * H))

ko1 = where(mo .gt. Ed, 0.424 * (1 - (H / 100)^1.7)+ 0.0694 * sqrt(W) * (1 - (H / 100)^8.), 0.424 * (1 - ((100 - H) / 100)^1.7) + 0.0694 * sqrt(W) * (1 - ((100 - H) / 100)^8))
kdw = ko1 * 0.581 * exp(0.0365 * T)

m = where(mo .gt. Ed, Ed + (mo - Ed) * 10^(-kdw), mo)
m = where(mo .lt. Ew, Ew - (Ew - mo) * 10^(-kdw), m)

m = m < 250.0
m = m > 0.0

Fo = 59.5 * (250. - m) / (147.2 + m)	;(Final ffmc calculation)

return(m)

end
