function calclinfit, x,y, noprint=noprint
	px = x(where(x ne 0))
	py = y(where(x ne 0))
	result=regress(transpose(px), py, replicate(1.0, n_elements(py)),$
		yfit, const, sigma, ftst, rval)

	if not keyword_set(noprint) then begin
		print, 'fit',result, 'const', const
		print, 'sigma', sigma, 'ftest', ftst
		print, 'R sq', (rval^2)
	endif

	return, [result, const]
end


pro densplot, img1, img2, ns, nl, imgout, lowx, hix, lowy, hiy, type1=type1, type2=type2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;; Plots img1 vs img2 (X and Y respectively) and shows
;; the density with greyscale levels
;;
;; 
;;	REQUIRED PARAMETERS
;;
;; img1 = First Input Image file name	(x)	(BYTE by default)
;; img2 = Second Input Image file name	(y)	(Float by default)
;; ns   = Number of samples	(both files must have the same ns and nl)
;; nl   = Number of lines
;; imgout = output file name
;;
;;
;;	OPTIONAL PARAMETERS
;;
;; lowx, hix, lowy, hiy specify the range and domain of the plot
;; Type1 = numeric type for img1 (1=byte,2=int,3=long,4=float,etc.  BYTE by default)
;; Type2 = numeric type for img2 (1=byte,2=int,3=long,4=float,etc.  FLOAT by default)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Tells the user if they are missing required parameters
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
if not keyword_set(imgout) then begin
	print, 'pro densplot, img1, img2, ns, nl, imgout, lowx, hix, lowy, hiy, type1=type1, type2=type2'
	return
endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Open the input files, and read the data into two arrays
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	openr, un1, /get, img1
	openr, un2, /get, img2

	if not keyword_set(type1) then type1 = 1	;;byte
	if not keyword_set(type2) then type2 = 4	;;float

	data1 = make_array(ns, nl, /nozero, type=type1)
	data2 = make_array(ns, nl, /nozero, type=type2)

	readu, un1, data1
	readu, un2, data2

	close, un1, un2
	free_lun, un1, un2

	print, 'Done Reading Files...'

	fit=calcLinFit(data1, data2)


	if type1 gt 3 then begin
		print, 'converting ', img1
		index = where(data1 lt 0)
		if index(0) ne -1 then $
			data1(index) = 0
		data1 = byte(data1 * 250)
	endif
	if type2 gt 3 then begin
		print, 'converting ', img2
		index = where(data2 lt 0)
		if index(0) ne -1 then $
			data2(index) = 0
		data2 = byte(data2 * 250)
	endif
	fit=calcLinFit(data1, data2)	;off for debugging , /noprint)
	print, fit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; If we aren't given bounds on the plot, set default
;; values to the full data range
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	if not keyword_set(lowx) then begin	lowx=MIN(data1)
	endif else if type1 gt 3 then		lowx = lowx * 250

	if not keyword_set(hix) then begin	hix=MAX(data1)
	endif else if type1 gt 3 then		hix = hix * 250

	if not keyword_set(lowy) then begin 	lowy=MIN(data2)
	endif else if type2 gt 3 then		lowy = lowy * 250

	if not keyword_set(hiy) then begin 	hiy=MAX(data2)
	endif else if type2 gt 3 then		hiy = hiy * 250

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Make the array for the outputplot
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	X_range = hix-lowx
	Y_range = hiy-lowy

	print, lowx, hix
	print, lowy, hiy
	print, X_range, Y_range
	fullrange = max([X_range, Y_range])
	output = lonarr(fullrange, fullrange)
	yratio = float(fullrange)/Y_range
	xratio = float(fullrange)/X_range

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; And this is where we do the real work.  
;;
;;  For all y values
;;	Find all the elements that match the current y value, 
;;	For all x values
;;		Of the matching y elements, count all the elements 
;;		that match the x value too and store that at out(x,y)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	for y=1, Y_range-1 do begin	
		curYs = where(data2 eq y+lowy)
		if curYs(0) ne -1 then begin
		for x=0, X_range-1 do begin
			index = where(data1(curYs) eq x+lowx)
;			if index(0) ne -1 then $
			output(xratio * x, yratio * (Y_range-y)) = n_elements(index)-1

		endfor
		endif
	endfor


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	Draw in the regression line.  color = max+20
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	linecolor=max(output)+20

	for i=0, fullrange-1 do begin

;;kind of a complicated mapping at this point we need to account for the stretch in x
;;  and the inversion stretch in y unfortunately this is accounted for in a different point
;; in the calculation in different parts of the program.  
		thispoint=yratio*(fit(1) + fit(0)*(i/xratio+lowx) + lowy)

		if thispoint gt 3 and thispoint lt fullrange-3 then begin
			output(i,fullrange-fix(thispoint)) = linecolor

;;make the line a little bit darker
			output(i,fullrange-(fix(thispoint)+1)) = linecolor
			output(i,fullrange-(fix(thispoint)-1)) = linecolor
			output(i,fullrange-(fix(thispoint)-2)) = linecolor
		endif
	endfor


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Write the output to a file and print the output ns, nl
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	openw, oun, /get, imgout
	writeu, oun, output
	close, oun
	free_lun, oun

	print, 'Number of samples = ', fullrange
	print, 'Number of lines   = ', fullrange

end
