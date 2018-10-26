
;Po is the previous day's DMC
; Le is length of day/ amount of sunlight

function calc_dmc(Po, T, ro, H, Le)                  ; DMC is Duff Moisture Code
local re, Mo, b, Mr, K, P
begin

re = where(ro .gt. 1.5, .92 * ro - 1.27, 0)    ;adjust precip
Mo = 20. + exp(5.6348 - (Po / 43.43))
b = 14. - 1.3 * log(Po)
b = where(Po .gt. 65., 6.2 * log(Po) - 17.2, b)
b = where(Po .lt. 33., 100. / (.5 + .3 * Po) , b)
Mr = where(re .gt. 0, Mo + (1000. * re / (48.77 + b * re)), 0) ;only if there's precip
Po = where(re .gt. 0, 244.72 - 43.43 * log(Mr - 20.), Po)       ;only if there's precip
Po = Po > 0.0
K = 1.894 * (T + 1.1) * (100 - H) * Le * 10^(-6)

P = (Po + 100 * K) > 0.0

return(P)

end
