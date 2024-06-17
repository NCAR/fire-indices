/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
The following variables should be specified as command-line arguments
 e.g.: ncl file=\"$file\" script.ncl

	precfile
	refprecfile (note this could be a list \(\/\"file1\",\"file2\",...,\"filen\"\/\) ) (the backslashes are getting out of hand -.- )
	tmaxfile
	output (the file to be written to)
	refstart (refstart=1980) (inclusive) (refstart/refend are numbers not strings)
	refend (refend=2010) (noninclusive)

Example of command-line to call kbdi_main:
ncl kbdi_main.ncl precfile=\"prec.METDATA.22i.nc\" refprecfile=\"prec.METDATA.22i.nc\" tmaxfile=\"tmax.METDATA.22i.nc\" output=\"kbdi.METDATA.22i.nc\" refstart=1980 refend=2010

;/

load "calc_kbdi.ncl"
load "check_time.ncl"
load "clip_time.ncl"

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

begin

read_precip = addfile(precfile, "r")
read_temper = addfile(tmaxfile, "r")

;read_refprecip = addfile(refprecfile, "r")
read_refprecip = addfiles(refprecfile, "r")	; for when the requested time period spans across files

timeP = read_precip->time
timeT = read_temper->time
check = check_time("precipitation", "temperature", timeP, timeT)

maximum = timeP(dimsizes(timeP)-1)
minimum = timeP(0)
if(check .eq. 0) then		;procedure clip_time finds the largest minimum and smallest maximum to create a uniform timeframe across all source files
	clip_time(timeT, minimum, maximum)
	print("Overlapping time limits are " + minimum + " to " + maximum)
	exit()
end if


system("rm -f "+output)
KBDI_out = addfile(output, "c") ; create new file to store KBDI
filedimdef(KBDI_out, "time", -1, True)	;makes time dimension unlimited

; copy / set global attributes
att_names = getvaratts(read_precip)
do i = 0, dimsizes(att_names)-1				;transfer global attributes of precip onto KBDI
	KBDI_out@$att_names(i)$ = read_precip@$att_names(i)$
end do

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL scripts check_time.ncl, clip_time.ncl, concert_prec.ncl, concert_temp.ncl, calc_kbdi.ncl, and kbdi_main.ncl from source files "+precfile+" and "+tmaxfile
KBDI_out@history = history

var_names = getfilevarnames(read_precip)

do i = 0, dimsizes(var_names)-1			;attach all variables but precipitation onto KBDI (lat, long, time)
	if (var_names(i) .ne. "prec") then	;@@@
		KBDI_out->$var_names(i)$ = read_precip->$var_names(i)$
	end if
end do

;read in daily precipitation
daily_precip = read_precip->prec

;read in maximum daily temperature
tmax = read_temper->tmax

;read in reference precipitation (isolate the time period first)
reftime_full = read_refprecip[:]->time
reftime_full_formatted = cd_calendar(reftime_full, 0)
reftime_ind = ind((reftime_full_formatted(:, 0) .ge. refstart) .and. (reftime_full_formatted(:,0) .lt. refend))
ref_precip = read_refprecip[:]->prec(reftime_ind, :, :)

;comment out this section if not debugging
printVarSummary(ref_precip)
reftime_sub = read_refprecip[:]->time(reftime_ind)
print(reftime_sub(0) + " " + reftime_sub(dimsizes(reftime_sub)-1))
printVarSummary(daily_precip)
printVarSummary(tmax)


calendar = read_precip->time@calendar

;units = (/ 0, 0 /)	;(/ tmax - degC, prec - mm/day /)
units = -1	;-1 corresponds to metadata

option = False
;option@suppressWarning = True

kbdi = calc_kbdi(daily_precip, tmax, ref_precip, calendar, units, option)

KBDI_out->kbdi = kbdi

end

