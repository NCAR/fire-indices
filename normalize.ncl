/;
2018, Copyright University Corporation for Atmospheric Research
;/

/;
 gsi is growing season index
 this function is necessary to ensure that greenup can be initialized everywhere by normalizing GSI
;/
function normalize(gsi)
local sort_gsi, min_gsi, max_gsi, min_index, max_index
begin

sort_gsi = dim_pqsort_n(gsi, 2, 0)
gsi_len = dimsizes(gsi(:, 0,0))
min_index = round(gsi_len * 0.005 - 1, 3) > 0
max_index = round(gsi_len * 0.995 - 1, 3)
min_gsi = sort_gsi(min_index, :, :)
max_gsi = sort_gsi(max_index, :, :)

latlen = dimsizes(gsi(0, :, 0))
lonlen = dimsizes(gsi(0, 0, :))

min_gsi1 = conform_dims((/gsi_len, latlen, lonlen/), min_gsi, (/1, 2/))
max_gsi1 = conform_dims((/gsi_len, latlen, lonlen/), max_gsi, (/1, 2/))

gsix = (gsi - min_gsi1) / (max_gsi1 - min_gsi1)

return(gsix)

end

