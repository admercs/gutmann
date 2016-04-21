pro refl, lsfile, outfile, ns, nl

;;must be bsq files

openr, lsun, /get, lsfile
openw, outun, /get, outfile

band = bytarr(ns, nl)
newband = intarr(ns, nl)

factor = fltarr(6)
factor(0) = 864.314
factor(1) = 331.717
factor(2) = 417.679
factor(3) = 277.245
factor(4) = 411.887
factor(5) = 448.812

for i=0, 5 do begin
	readu, lsun, band
	newband = FIX(10000* (FLOAT(band)/factor(i)))
	writeu, outun, newband
endfor


free_lun, outun, lsun

end