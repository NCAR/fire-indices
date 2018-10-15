
;Calculate modified Fosberg Fire Weather Index
;daily index
;U is windspeed in mph
;h is relative humidity in percent
;T is temperature in degrees Fahrenheit
;Q is KBDI

function calc_mFFWI( U, h, T, Q , emc)
local mFFWI, FFWI, FAF, bf, eta, M, d00, d01, d10, d11, d20, em0, em, c1, c2, c3
;mFFWI is modified FFWI, FFWI is Fosberg Fire Weather Index, FAF is Fuel Availability Factor
begin

c1 = 1.0
c2 = 1.5
c3 = -0.5

em0 = 0.72
em = 0.000002

bf = 1. / 0.3002

eta = 1 - 2 * (emc / 30) + c2 * (emc / 30) ^ 2 + c3 * (emc / 30) ^ 3

FFWI = bf * eta * (1 + U^2.)^0.5

FAF = em0 + (em * Q^2.)

mFFWI = Q
mFFWI = FAF * FFWI

return(mFFWI)

end
