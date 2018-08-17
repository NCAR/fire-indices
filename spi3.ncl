; NCL script to calculate 3 month spi from precipitation

;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"     ;are all these necessary for this code/ are there additional ones necessary

;; The following variables should be specified as command-line arguments
;; e.g.: ncl file=\"$file\" script.ncl

;precip_in = "pr.eval.ERA-Int.RegCM4.mon.NAM-22i.raw.nc" ;read from here
;output = "spi3.nc"  ;write to here

begin

read_prec = addfile(precip_in, "r") ;read in monthly precip data

system("rm -f "+output) 
spi_out = addfile(output, "c") ;create new file to store three month spi (current and previous lines)

filedimdef(spi_out, "time", -1, True) ; make time dimension unlimited

;copy/set global attributes
 
att_names = getvaratts(read_prec)

do i = 0,dimsizes(att_names)-1                         ;transfer global attributes of inputs onto global attributes of output
  spi_out@$att_names(i)$ = read_prec@$att_names(i)$
end do

history = "Created " + systemfunc("date") + " by "+systemfunc("whoami")+"@"+systemfunc("hostname")+" using NCL script from source file "+prec_in
spi_out@history = history

; copy variables

var_names = getfilevarnames (read_prec)

do i = 0, dimsizes(var_names)-1       ;get all variable attributes except for precip attached to spi, not sure if all these should be here
   if (var_names(i) .ne. "pr") then
       spi_out->$var_names(i)$ = read_prec->$var_names(i)$
   end if
end do

;calculate 3 month SPI

SPI = read_prec->pr    ;preserve coordinate variable in output
time_span = 3
option = False
dimen = 0

SPI = dim_spi_n(SPI, time_span, option, dimen)

delete_VarAtts(SPI, -1) ;get rid of superfluous attributes

SPI@long_name = time_span+" Month Standardized Precipitation Index"   ; Is there convention for what long names should be?

varatts = (/"units", "missing_value", "_FillValue"/)

SPI@$varatts(0)$ = "1"

do i = 1, dimsizes(varatts)-1     ; transfer "missing value" and "_FillValue" from precip data
   SPI@$varatts(i)$ = read_prec->pr@$varatts(i)$
end do

spi_out->spi = SPI     ;create spi variable, assign value

end

