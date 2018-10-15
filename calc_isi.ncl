;m is an intermediate step from FFMC

function calc_isi(W, m)                      ; ISI is Initial Spread Index
local fw, ff, r
begin

fw = exp(.05039 * W)
ff = 91.9 * exp(-0.1386 * m) * (1 + (m^5.31 / (4.93 * 10^7)))
r = (0.208 * fw * ff) > 0.0

return(r)

end

