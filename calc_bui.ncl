;P is DMC, D is DC

function calc_bui(P, D)                      ; BUI is Build Up Index
local dfour, D1, P1, U
begin
D1 = where(P .eq. 0. .and. D .eq. 0., D@_FillValue, D)
P1 = where(P .eq. 0. .and. D .eq. 0., P@_FillValue, P)

dfour = .4 * D1

U = where(P1 .gt. dfour, P1 - (1. - .8 * D1 / (P1 + dfour)) * (.92 + (0.0114 * P1)^1.7), 0.8 * P1 * D1 / (P1 + dfour))
U = where(ismissing(D1), 0., U)

U = U > 0.0             ;not a check explicitly stated in the paper, but prevents calculations that result in non-real numbers

return(U)

end

