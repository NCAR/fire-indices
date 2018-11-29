/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
 This function calculates EMC, or equilibrium moisture content
 T is temperature
 H is humidity
 emc is equilibrium moisture content
;/
function calc_emc( T, H )
local emc
begin

emc = 2.22749 + 0.160107 * H - 0.014784 * T
emc = where(H .lt. 10., 0.03229 + .281073 * H - .000578 * T * H, emc)
emc = where(H .gt. 50., 21.0606 + 0.005565 * (H^2.0) - 0.00035 * H * T - 0.483199 * H, emc)

return(emc)

end


