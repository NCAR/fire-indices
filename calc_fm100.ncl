/;
 emcbar is average equilibrium moisture content
 pptdur is precipitation duration
 yfm is yesterday's fm100
 fr100 is a constant
;/
function calc_fm100(emcbar, pptdur, yfm, fr100)
local bndryh, fm100, fm_100
begin

bndryh = ((24. - pptdur) * emcbar + pptdur * (0.5 * pptdur + 41.0)) / 24.
fm100 = (bndryh - yfm) * fr100 + yfm
fm_100 = dble2flt(fm100)
return(fm_100)

end


