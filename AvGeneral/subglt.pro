pro subglt, infname, samples, lines, startline, finishline, outfname

;;Reads a glt file and creates a subsetted file with only the pixels which fall
;;	between startline and finishline
;;
;;	infname - full glt file
;;	samples, lines - samples and lines of full glt file
;;	startline, finishline - line numbers to include in subset (inclusive)
;;	outfname - subsetted glt filename
;;
;; assumes the glt input file is BIL integer values

print, ' '
print, 'This program assumes the glt file you are subsetting is in INTEL byte order and BIL!!!'

openr, /get, gltun, infname
openw, /get, subgltun, outfname

curline = intarr(samples, 2)	;;one line with both bands
outline = intarr(samples, 2)

;;initialize the output line
outline(*,*) = 0


;;this is where the main body of work is done
;; read each line and copy good values to outline, then write outline
for i=1, lines do begin
	readu, gltun, curline


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;VERY IMPORTANT LINE;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	byteorder, curline	;; if INTEL byte order, use this line
;				;; if IEEE byte order, do NOT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;VERY IMPORTANT LINE;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;this also only gets the positive values, not the negative ones
	index = where((abs(curline(*,1)) ge startline) and (abs(curline(*,1)) le finishline), count)
	if (index(0) ne -1) then begin
		outline(index, 0) = curline(index,0)
		outline(index, 1) = curline(index,1)
		writeu, subgltun, outline
	end
;;	writeu, subgltun, outline
	outline(*,*) = 0	;;reset the output line
end

close, gltun
close, subgltun
free_lun, gltun
free_lun, subgltun

end