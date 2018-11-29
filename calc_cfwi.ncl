/;
2018, Copyright University Corporation for Atmospheric Research
;/


;R is ISI
;U is BUI

function calc_cfwi(U, R)
local fd, B, S
begin

fd = where(U .gt. 80., 1000. / (25. + 108.64 * exp(-0.023 * U)), 0.626 * U^0.809 + 2)
B = 0.1 * R * fd
S = where(B .gt. 1., exp(2.72 * (.434 * log(B))^.647), B)

S = S > 0.0

return(S)

end

