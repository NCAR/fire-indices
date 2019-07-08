/;
2018, Copyright University Corporation for Atmospheric Research
;/


load "calc_julian_day.ncl"
load "calc_vpd.ncl"
load "calc_gsi.ncl"
load "normalize.ncl"
load "find_first.ncl"
load "adjust.ncl"
load "calc_potential_solar.ncl"
load "calc_sow_daily.ncl"
load "calc_pduration.ncl"
load "calc_point_pduration.ncl"
load "calc_paper_pduration.ncl"
load "calc_emc.ncl"
load "calc_x1000.ncl"
load "calc_mcherb.ncl"
load "calc_mcwood.ncl"
load "calc_vegstage.ncl"
load "calc_just_erc.ncl"
load "calc_erc.ncl"
load "convert_temp.ncl"
load "convert_prec.ncl"
load "convert_humid.ncl"
load "check_time.ncl"
load "clip_time.ncl"

/;
The following variables should be specified as command-line arguments
 e.g.: ncl file=\"$file\" script.ncl

precfile
rsdsfile
hussfile
rhmaxfile
rhminfile
tmaxfile
tminfile
fm1000file
fm100file
output

optionally:
elev_in
z3_in   ; this is a coefficient for converting precipitation amount to precipitation duration

;/


;Calculate ERC with these inputs:
/;
precipitation (in mm)
solar radiation (Downwelling shortwave radiation, in W m-2)
specific humidity (kg/kg)
maximum and minimum relative humidity (on a 0 to 100 scale)
maximum and minimum temperature (in Celsius)
optionally, altitude	(default is 500 m)

secondarily,
latitude
longitude
time
;/

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

begin

r_pr = addfile(precfile, "r")
r_rad = addfile(rsdsfile, "r")
r_rhmax = addfile(rhmaxfile, "r")
r_rhmin = addfile(rhminfile, "r")
r_tmax = addfile(tmaxfile, "r")
r_tmin = addfile(tminfile, "r")
r_fm1000 = addfile(fm1000file, "r")
r_fm100 = addfile(fm100file, "r")
r_huss = addfile(hussfile, "r")
;r_z3 = addfile(z3_in, "r")
r_z3 = addfile("pdur_jolly_regrid.nc", "r")
r_const = addfile("erc_constants.nc", "r")	; must be in right directory!!
;r_elev = addfile(elev_in, "r")

; if fm100 and fm1000 have been calculated, temperature, precipitation, and humidity must already match in every dimension. Only need to check time for specific humidity, solar radiation compared to fm100
timeSH = r_huss->time
timeR = r_rad->time
time100 = r_fm100->time

check = check_time("specific humidity", "solar radiation", timeSH, timeR)
check = check + check_time("solar radiation", "FM100", timeR, time100)

maximum = time100(dimsizes(time100)-1)
minimum = time100(0)
if(check .lt. 2) then           ;procedure clip_time finds the largest minimum and smallest maximum to find a uniform timeframe across all source files
	clip_time(timeSH, minimum, maximum)
	clip_time(timeR, minimum, maximum)
        print("Overlapping time limits are " + minimum + " to " + maximum)
        exit()
end if

print("Time limits match on all variables")


system("rm -f "+output)
w_erc = addfile(output, "c") ;create new file to store erc

filedimdef(w_erc, "time", -1, True) ; make time dimension unlimited

;copy/set global attributes
att_names = getvaratts(r_pr)

do i = 0,dimsizes(att_names)-1                         ;transfer global attributes of inputs onto global attributes of output
  w_erc@$att_names(i)$ = r_pr@$att_names(i)$
end do

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL scripts erc_main.ncl, calc_julian_day.ncl, calc_vpd.ncl, calc_gsi.ncl, normalize.ncl, find_first.ncl, adjust.ncl, calc_potential_solar.ncl, calc_sow_daily.ncl, calc_pduration.ncl, calc_point_pduration.ncl, calc_paper_pduration.ncl, calc_emc.ncl, calc_x1000.ncl, calc_mcherb.ncl, calc_mcwood.ncl, calc_vegstage.ncl, and calc_erc.ncl, from source file "+precfile+ ", "+rsdsfile+ ", "+rhmaxfile+ ", "+rhminfile+ ", "+tmaxfile+ ", "+tminfile+ ", "+fm1000file+ ", "+fm100file+", "+"pdur_jolly_regrid.nc"+", "+hussfile
w_erc@history = history

; copy variables
var_names = getfilevarnames(r_pr)

do i = 0, dimsizes(var_names)-1
   if (var_names(i) .ne. "prec") then
       w_erc->$var_names(i)$ = r_pr->$var_names(i)$
   end if
end do


; initialize inputs
lat = r_pr->lat
lon = r_pr->lon
time = r_pr->time

maxtC = r_tmax->tmax	;NOTE: temperature is actually needed in Celsius AND Fahrenheit!
convert_temp("degC", maxtC)	;convert to Celsius if not already
maxt = maxtC * 1.8 + 32.	;Celsius to Fahrenheit
mintC = r_tmin->tmin
convert_temp("degC", mintC)
mint = mintC * 1.8 + 32.

maxrh = r_rhmax->rhmax
minrh = r_rhmin->rhmin
convert_humid("%", maxrh)
convert_humid("%", minrh)

temp1 = maxt - 2.
rh1 = minrh + 2.
prec = r_pr->prec
convert_prec("inches/day", prec)
rad = r_rad->rsds
fm1000 = r_fm1000->fm1000       ;calculated in a different file
fm100 = r_fm100->fm100
huss = r_huss->huss
b = r_z3->Z3
;elev = r_elev->orog
elev = 500.

erc = calc_erc(time, prec, maxtC, mintC, maxrh, minrh, lat, lon, rad, huss, b, fm100, fm1000)

/;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

latlen = dimsizes(lat)
lonlen = dimsizes(lon)
timelen = dimsizes(time)

day_year = calc_julian_day(time)
tempsolar = calc_potential_solar(lat,day_year, elev)
maxsolar = conform_dims((/timelen, latlen, lonlen/), tempsolar, (/0,1/))
sow = calc_sow_daily(rad, prec, maxsolar)

annperen = "annual"     ; in MATLAB code, 1 == annual, 2 == perennial
climat = 3	;climat is NFDRS Climate class
pptdur = calc_pduration(b, prec, latlen, lonlen)	; if not using z3 as an input, use calc_paper_pduration. if only operating on 1 point, use calc_point_pduration.

;READ IN ALL THE CONSTANTS. For right now, always use fuel model G to match other literature
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
;warmdays = prec(0, :, :)
;warmdays = 0.
;gdd = prec(0, :, :)
;gdd = 0.
ymherb = prec(0, :, :)
ymherb = 50.
ymwood = ymherb


vpd = calc_vpd(maxtC, mintC, huss, rh1, elev)           ;the vpd function requires Celsius
gsi = calc_gsi(mint, lat, vpd, day_year, lonlen)
gsi_norm = normalize(gsi)

greenup = find_first(gsi_norm, day_year, latlen, lonlen)

yx1000 = fm1000(0, :, :)
ym1000 = fm1000(0, :, :)

pregrns = (/50.0,60.0,70.0,80.0/)
pregrn = pregrns(climat -1)

tmpprm = temp1
rhprm = rh1
adjust(tmpprm, rhprm, sow)	;this is adjusted temperature and humidity at the fuel-atmosphere interface, as opposed to what is measured at a weather station
emcprm = calc_emc(tmpprm, rhprm)	;emcprm is equilibrium moisture content at the fuel-atm interface

fm1 = where(sow .gt. 4, 35.0, 1.03 * emcprm)
fm10 = where(sow .gt. 4, 35., 1.28 * emcprm)

mcwodi = ymherb
mcwodi = (/pregrn/)
mcherbi = fm1

erc = prec	;establishes lat, lon, etc.
ndays = dimsizes(time) - 1

do i=0, ndays

        year = tointeger(floor(i / 365.2425))
        j_green = greenup(year, :, :)

        x1000 = calc_x1000(fm1000(i, :, :), ym1000, yx1000, maxt(i, :, :), mint(i, :, :), hveg)

        gren = where(hveg .eq. "greenup", 100. * greendays / (7 * climat), -1.0)

        mcherb  = calc_mcherb(fm1(i, :, :), mcherbi(i, :, :), fm1000(i, :, :), ym1000, greendays, climat, hveg, annperen, x1000, ymherb, gren)
        greendays = where(hveg .eq. "greenup", greendays + 1, greendays)
        mcwood = calc_mcwood(pregrn, mcwodi, fm1000(i, :, :), climat, hveg, gren, ymwood)

        hveg = calc_vegstage(colddays, maxt(i, :, :), mint(i, :, :), day_year(i), j_green, gren, mcherb, hveg)
        erc(i, :, :) = (/calc_erc(w1d, w10d, w100d, w1000d, wherb, wwood, mcherb, depth, sg1d, sg10d, sg100d, sg1000d, sgherb, sgwood, fm1(i, :, :), fm10(i, :, :), fm100(i, :, :), fm1000(i, :, :), mcwood, extmoi, hd)/)

	colddays = where(hveg .eq. "curing" .and. mint(i, :, :) .lt. 32., colddays + 1, colddays)
	colddays = where(hveg .eq. "frozen", 0, colddays)
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;/


w_erc->erc = erc	;transfer erc data into file

end



