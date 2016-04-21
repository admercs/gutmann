;; takes the ratio of a landsat and an aviris image, then calculates the slope 
;;	across the image for all bands, assumes both are in BSQ format!
;;
;;	outputs a binary file containing slope, y-int and 8 pts/band
;;
;;	ethan gutmann 02/08/00

pro eightpoints, avfile, lsfile, ns, nl, nb, outfile

openr, avun, /get, avfile
openr, lsun, /get, lsfile

avband = intarr(ns, nl)
lsband = intarr(ns, nl)
curline = fltarr(ns, nb)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  create an array of average ratio values across all samples and bands
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
for i=0, nb-1 do begin
	readu, avun, avband
	readu, lsun, lsband
	
	curline[*,i] =	((total(lsband, 2) / total(lsband ne 0, 2))/ $
			(total(avband, 2) / total(avband ne 0, 2)))

endfor
close, avun, lsun
free_lun, avun, lsun

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Calculate the slope, y-intercept, and r values at each band
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

slope = fltarr(nb)
r = fltarr(nb)
const = fltarr(nb)

for i=0, nb-1 do begin
	slp = regress(transpose(indgen(ns)), curline(*,i), $
			replicate(1.0, ns), $
			yfit, constval, sigma, ftst, rval)
	slope[i] = slp
	r[i] = rval
	const[i] = constval

endfor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	write to outfile containing y-int, slope, eightvalues/band
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ate = fltarr(8, nb)

for i=0, nb-1 do begin
	for j=0, 7 do begin
		ate(j,i)=total(curline((j*(ns/8)):((j+1)*ns/8)-1, i)) / (ns/8)
	endfor
endfor

openw, outun, /get, outfile

for i=0, nb-1 do begin
	writeu, outun, slope[i], const[i], ate[*,i]
endfor

close, outun
free_lun, outun

end