;; designed for integer (ie calibrated) ls data, on a subset small enough
;;	to be able to read an entire band at a time (must be BSQ)
;;
;;	baseLS	= file you are forcing TO
;;	newLS	= file you are forcing from
;;	outLS	= output file
;;
;;	ns,nl,ns= samples, lines, bands

pro forceLS2LS, baseLS, newLS, ns, nl, nb, outLS

openr, bun, /get, baseLS
openr, nun, /get, newLS
openw, oun, /get, outLS

bband = intarr(ns, nl)
nband = intarr(ns, nl)


for i=1, nb do begin
	readu, bun, bband
	readu, nun, nband

	bave = total(bband)/total(where(bband ne 0) ne -1)
	nave = total(nband)/total(where(bband ne 0) ne -1)

	print, FLOAT(bave)/nave	

	nband = FIX(nband* (FLOAT(bave)/nave))
	
	writeu, oun, nband
endfor

free_lun, oun, nun, bun

end