;; Performs a rough correction for BRDF on an aviris cube.  
;;
;;input	- one aviris cube (filename)
;;	- one file containing "slope" values for each aviris band (filename)
;;	- one output filename
;;	- number of samples, lines, bands
;;
;;	AVIRIS cube must already be ground calibrated but not geocorrected.  
;;	the slope file must be Slope, Y-intercept columns
;;
;;	Ethan Gutmann 12/6/99
;;

pro RoughBRDF, avFile, slopeFile, outFile, ns, nl, nb


;;;;;;;;;;;;;;;;;;;;	INITIALIZATION	;;;;;;;;;;;;;;;;;;;;
;;	open and or read files, set up sample correction array

cols = load_cols(slopeFile, slope)

openr, avun, avFile, /get
openw, outun, outFile, /get



;;;;;;;;;;;;;;;;;;;;	Main Program	;;;;;;;;;;;;;;;;;;;;
;; set a 2x2 array to calculate distance and band correction factors
;;
;;	then we will read in one 614x224 line at a time, correct it, 
;;	and write it back to disk in a new file (outFile)



;; we will multiply each av line by lineCorrect to remove brdf effects
lineCorrect = fltarr(nb,ns)

midvals = slope(1,*)+fix(ns/2)*slope(0,*)
for i=0, ns-1 do begin
	lineCorrect[*,i] = midvals / (slope(1,*)+slope(0,*)*(i))
end



curLine = intarr(nb,ns)	;; 2D array for a single line
newLine = intarr(nb,ns)	;; 2D array for output

for i=0, nl-1 do begin
	readu, avun, curLine
	newLine = fix(curLine * lineCorrect)
	writeu, outun, newLine

end



;;;;;;;;;;;;;;;;;;;;	TERMINATION CLEANUP	;;;;;;;;;;;;;;;;;;;;
close, avun
free_lun, avun

close, outun
free_lun, outun

end