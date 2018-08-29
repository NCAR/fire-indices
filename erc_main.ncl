load "calc_vpd.ncl"
load "calc_gsi.ncl"
load "normalize.ncl"
load "find_first.ncl"
load "adjust.ncl"
load "calc_sow_daily.ncl"
load "calc_pduration.ncl"
load "calc_point_pduration.ncl"
load "calc_paper_pduration.ncl"
load "calc_emc.ncl"
load "calc_fm1.ncl"
load "calc_fm10.ncl"
load "calc_x1000.ncl"
load "calc_mcherb.ncl"
load "calc_mcwood.ncl"
load "calc_prelim_vegstage.ncl"
load "calc_vegstage.ncl"
load "calc_erc.ncl"

/;
The following variables should be specified as command-line arguments
 e.g.: ncl file=\"$file\" script.ncl

precip_in
solrad_in
rhmax_in
rhmin_in
tmpmax_in
tmpmin_in
fm1000_in
fm100_in
output
const_in

optionally:
elev_in
z3_in   ; this is a coefficient for converting precipitation amount to precipitation duration

;/


;Calculate ERC with these inputs:
/;
precipitation
solar radiation
maximum and minimum relative humidity
maximum and minimum temperature
optionally, altitude

secondarily,
latitude
longitude
time
;/


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

begin

r_pr = addfile(precip_in, "r")
r_rad = addfile(solrad_in, "r")
r_rhmax = addfile(rhmax_in, "r")
r_rhmin = addfile(rhmin_in, "r")
r_tmax = addfile(tmpmax_in, "r")
r_tmin = addfile(tmpmin_in, "r")
r_fm1000 = addfile(fm1000_in, "r")
r_fm100 = addfile(fm100_in, "r")
r_huss = addfile(spchum_in, "r")
r_z3 = addfile(z3_in, "r")
r_const = addfile(const_in, "r")
;r_elev = addfile(elev_in, "r")

system("rm -f "+output)
w_erc = addfile(output, "c") ;create new file to store three month spi (current and previous lines)

filedimdef(w_erc, "time", -1, True) ; make time dimension unlimited

;copy/set global attributes

att_names = getvaratts(r_pr)

do i = 0,dimsizes(att_names)-1                         ;transfer global attributes of inputs onto global attributes of output
  w_erc@$att_names(i)$ = r_pr@$att_names(i)$
end do

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL script from source file "+precip_in+ ", "+solrad_in+ ", "+rhmax_in+ ", "+rhmin_in+ ", "+tmpmax_in+ ", "+tmpmin_in+ ", "+fm1000_in+ ", "+fm100_in
w_erc@history = history

; copy variables

var_names = getfilevarnames(r_pr)

do i = 0, dimsizes(var_names)-1
   if (var_names(i) .ne. "prec") then
       w_erc->$var_names(i)$ = r_pr->$var_names(i)$
   end if
end do


; initialize the following
lat = r_pr->lat
lon = r_pr->lon
time = r_pr->time

maxtC = r_tmax->tmax
;maxtC = maxt - 273.15
maxt = maxtC * 1.8 + 32.
mintC = r_tmin->tmin
;mintC = mint - 273.15
mint = mintC * 1.8 + 32.                ;Celsius to Fahrenheit
maxrh = r_rhmax->rhmax
minrh = r_rhmin->rhmin
temp1 = maxt - 2.
rh1 = minrh + 2.
prec = r_pr->prec
prec = prec / 24.5      ;mm to inches
rad = r_rad->rsds
;surface_downwelling_shortwave_flux_in_air
mc1000 = r_fm1000->fm1000       ;calculated in a different file
mc100 = r_fm100->fm100
huss = r_huss->huss
b = r_z3->Z3
;elev = r_elev->orog
elev = 500.

latlen = dimsizes(lat)
lonlen = dimsizes(lon)
timelen = dimsizes(time)
day_year = calc_julian_day(time)
tempsolar = calc_potential_solar(lat,day_year, elev)
maxsolar = conform_dims((/timelen, latlen, lonlen/), tempsolar, (/0,1/))

sow = calc_sow_daily(rad, prec, maxsolar)

annperen = "annual"     ; in MATLAB code, 1 == annual, 2 == perennial
climat = 3
pptdur = calc_pduration(b, prec, latlen, lonlen)

;READ IN ALL THE CONSTANTS. For right now, always use fuel model G
fuel_mod = 6    ;0=A, 1=B, 2=C, 3=D, 4=E, 5=F, 6=G, 7=H, 8=I, 9=J etc
w1d = r_const->w1(fuel_mod)
w10d = r_const->w10(fuel_mod)
w100d = r_const->w100(fuel_mod)
w1000d = r_const->w1000(fuel_mod)
wherb = r_const->whrb(fuel_mod)
wwood = r_const->wwd(fuel_mod)
depth = r_const->dp(fuel_mod)
sg1d = r_const->s1(fuel_mod)
sg10d = r_const->s10(fuel_mod)
sg100d = r_const->s100(fuel_mod)
sg1000d = r_const->s1000(fuel_mod)
sgherb = r_const->shrb(fuel_mod)
sgwood = r_const->swd(fuel_mod)
extmoi = r_const->emo(fuel_mod)
hd = r_const->hd(fuel_mod)

c1 = 0.046

w1d = w1d * c1
w10d = w10d * c1
w100d = w100d * c1
w1000d = w1000d * c1
wherb = wherb * c1
wwood = wwood * c1              ; conversions from T/Ac to lbs/ft^2

hveg = conform_dims((/latlen, lonlen/), "pregreen", -1)                ; pregreen, greenup, green, transition, cured, frozen
greendays = prec(0, :, :)
greendays = 0.
colddays = prec(0, :, :)
colddays = 0.
warmdays = prec(0, :, :)
warmdays = 0.
gdd = prec(0, :, :)
gdd = 0.
ymherb = prec(0, :, :)
ymherb = 50.
ymwood = ymherb


vpd = calc_vpd(maxtC, mintC, huss, rh1, elev)           ;the vpd function requires Celsius
gsi = calc_gsi(mint, lat, vpd, day_year, lonlen)
gsi_norm = normalize(gsi)

greenup = find_first(gsi_norm, day_year, latlen, lonlen)

yx1000 = mc1000(0, :, :)
ym1000 = mc1000(0, :, :)

pregrns = (/50.0,60.0,70.0,80.0/)
pregrn1 = pregrns(climat -1)

tmpprm = temp1
rhprm = rh1
adjust(tmpprm, rhprm, sow)             ;current MATLAB code does not adjust but it probably should
emcprm = calc_emc(tmpprm, rhprm)

mc1 = calc_fm1(emcprm, sow)             ; calculate fm1 and fm10
mc10 = calc_fm10(emcprm, sow)

mcwodi = ymherb
mcwodi = (/pregrn1/)
mcherbi = mc1

erc = prec
ndays = dimsizes(time) - 1

do i=0, ndays

        year = tointeger(floor(i / 365.2425))
        j_green = greenup(year, :, :)
        hveg = calc_prelim_vegstage(hveg, warmdays, colddays, day_year(i), j_green, gdd)
;       j_green = where( greendays .eq. 0 .and. hveg .eq. "greenup", day_year(i), j_green)      ;any point to this line at this point????
        gdd = where(warmdays .gt. 5, gdd + (maxt(i, :, :) + mint(i, :, :)) / 2. - 32., 0)

        x1000 = calc_x1000(mc1000(i, :, :), ym1000, yx1000, maxt(i, :, :), mint(i, :, :), hveg)

        gren = where(hveg .eq. "greenup", 100. * greendays / (7 * climat), -1.0)

        mcherb  = calc_mcherb(mc1(i, :, :), mcherbi(i, :, :), mc1000(i, :, :), ym1000, greendays, climat, hveg, annperen, x1000, ymherb, gren)
        greendays = where(hveg .eq. "greenup", greendays + 1, greendays)
        mcwood = calc_mcwood(pregrn1, mcwodi, mc1000(i, :, :), climat, hveg, gren, ymwood)

        hveg = calc_vegstage(warmdays, colddays, gdd, maxt(i, :, :), mint(i, :, :), day_year(i), j_green, gren, mcherb, hveg)
        erc(i, :, :) = (/calc_erc(w1d, w10d, w100d, w1000d, wherb, wwood, mcherb, depth, sg1d, sg10d, sg100d, sg1000d, sgherb, sgwood, mc1(i, :, :), mc10(i, :, :), mc100(i, :, :), mc1000(i, :, :), mcwood, extmoi, hd)/)

        colddays = where(hveg .eq. "cured" .and. mint(i, :, :) .lt. 32., colddays + 1, colddays)
        colddays = where(hveg .eq. "greenup" .or. hveg .eq. "frozen", 0., colddays)
        warmdays = where(maxt(i, :, :) .gt. 32., warmdays + 1, 0.)

        yx1000 = (/x1000/)
        ymherb = (/mcherb/)
        ymwood = (/mcwood/)

end do

delete_VarAtts(erc, -1) ;get rid of superfluous attributes

erc@long_name = "Energy Release Component"   ; No convention for long names, just make it descriptive

varatts = (/"units", "missing_value", "_FillValue"/)

erc@$varatts(0)$ = "1"

do i = 1, dimsizes(varatts)-1     ; transfer "missing value" and "_FillValue" from precip data
   erc@$varatts(i)$ = r_pr->prec@$varatts(i)$
end do

w_erc->erc = erc

end



