;; takes the ratio of a landsat and an aviris image, then calculates the slope 
;;	across the image for all bands, assumes both are in BSQ format!
;;
;;	outputs an ascii file of 
;;
;;	ethan gutmann 1/11/00

pro asciratioslopeCalc, avfile, lsfile, ns, nl, nb, outfile

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

	avels = total(lsband, 2) / total(lsband ne 0, 2)

	ave = total(avels, 1)/total(avels ne 0, 1)

	curline[*,i] = ave / curline[*,i]
endfor


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  print values
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


for i=0, nb-1 do begin
	openw, outun, /get, outfile + strtrim(string(i+1), 2)
	for j=0, ns-1 do begin
		printf, outun, curline(j,i)
	end
	close, outun
	free_lun, outun

end

close, avun, lsun
free_lun, avun, lsun

end