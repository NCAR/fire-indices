
;Do is the previous day's DC
;Lf is an adjustment to length of day

function calc_dc(ro, T, Do, Lf)                      ; DC is Drought Code
local rd, Qo, Qr, Dr, V, Drou
begin

rd = where(ro .gt. 2.8, 0.83 * ro - 1.27, -1)   ;adjust precip

Qo = 800 * exp(-Do / 400.)
;Qr = where(rd .gt. 0., Qo + (3.937 * rd), -1)           ;only if precip
Qr = Qo + (3.937 * rd)
Dr = where(rd .gt. 0., 400. * log(800. / Qr), Do)       ;only if precip
Dr = Dr > 0.0

V = (.36 * (T + 2.8)) + Lf
V = V > 0
Drou = (Dr + .5 * V) > 0.0

return(Drou)

end

