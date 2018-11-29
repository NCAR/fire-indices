/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
This script implements the repmiss procedure. It takes one input named infile, which can be any variable, and applies the repmiss procedure.
;/

load "repmiss.ncl"

begin

input = addfile(infile, "w")
var = input->tmax		;MODIFY to hold whichever variable you require

repmiss(var)

input->tmax = var               ;MODIFY to hold whichever variable you require

end

