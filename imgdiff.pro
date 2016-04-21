;; calculates the average difference between all pixels of two images
;; assumes float bsq format, if either contains 0 values that should be
;;	removed, it must be img1

pro imgDiff, img1, img2, ns, nl, nb

openr, un1, /get, img1
openr, un2, /get, img2

band1 = fltarr(ns, nl)
band2 = fltarr(ns, nl)
diff = fltarr(ns, nl)


for i=1, nb do begin

	readu, un1, band1
	readu, un2, band2

	diff = abs(band1(where(band1 ne 0)) - band2(where(band1 ne 0)))
	print, total(diff/(total(band1 ne 0)))
	
endfor

close, un1, un2
free_lun, un1, un2

end