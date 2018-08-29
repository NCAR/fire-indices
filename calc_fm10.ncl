/;
 sowc is State of Weather Code
 emcprm is the equilibrium moisture content at the fuel atm interface and has had temp and humid adjustments
;/
function calc_fm10(emcprm, sowc)
local fm10
begin

fm10 = where(sowc .gt. 4, 35., 1.28 * emcprm)
return(fm10)

end

