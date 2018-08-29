/;
 sowc is State of Weather Codes
 emcprm is the equilibrium moisture content at the fuel atm interface and has had temp and humid adjustments
;/
function calc_fm1(emcprm, sowc)
local fm1
begin

fm1 = where(sowc .gt. 4, 35.0, 1.03 * emcprm)
return(fm1)

end


