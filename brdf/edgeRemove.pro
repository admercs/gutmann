;; edgeRemove.pro
;;	Reads an INTEGER BSQ image file.  Traces around the edge of the actual
;;	image (assumeing there is blackspace surrounding the image), and removes
;;	the outer two pixels.  This is useful for cc-warped images in which the
;;	outer pixels have been averaged with black pixels, and thus are useless
;;
;;	Requires that the image be small enough that an entire band can be read
;;	into memory at once.  It must be Integer and BSQ format (int could be changed
;;	to byte easily though)
;;
;;	Ethan Gutmann	1/9/99
;;


pro edgeRemove, imgFname, samples, lines, bands, outputFname

;;movex and movey arrays are used to move the x and y values around in a circle
;;
;;	directions correspond to the following
;;		123
;;		0 4
;;		765

movex = [-1,-1, 0, 1, 1, 1, 0,-1]
movey = [ 0,-1,-1,-1, 0, 1, 1, 1]

true = 1
false = 2

notfound = true

img = intarr(samples, lines, bands)

openr, imageFile, /get, imgFname
openw, outputFile, /get, outputFname

midpoint = fix(lines/2)

;; we could use a for loop here if the image was too large to completely read in
;;for i=1, bands do begin

	readu, imageFile, img


;; find the first non-zero element on the midpoint line 
	dex=where(img[*,midpoint,0] ne 0)
	k=dex[0]

;
; silly for loops...
;
;	for j=0, samples do begin
;		if img(j, midpoint, 0) ne 0 then begin
;			k = j
;			j = samples	;;break the for loop
;		endif
;	endfor

	print, 'found ', k, midpoint


;; k now contains the sample number of the first non-zero pixel
;;	on the midpoint line.  we will make j be the y coordinate now

	j = midpoint
	last = 0	;; the last direction we came from

	for a=0, 3 do begin

		for b=0, 10 do begin
			img(k, j, *) = 0

			notfound = true
			while(notfound) do begin	;;we assume we will find one
				last = (last+1) mod 8
				x = k + movex(last)
				y = j + movey(last)
				
				if img(x,y,0) ne 0 then begin
					k = x
					j = y
					notfound = false
					last = (last+4) mod 8
				endif
			endwhile
		endfor


		while (j ne midpoint) do begin
			img(k, j, *) = 0

			notfound = true
			while(notfound) do begin	;;we assume we will find one
				last = (last+1) mod 8
				x = k + movex(last)
				y = j + movey(last)
				
				if img(x,y,0) ne 0 then begin
					k = x
					j = y
					notfound = false
					last = (last+4) mod 8
				endif
			endwhile
		endwhile
		print, k, j
	endfor

	writeu, outputFile, img

	close, outputFile
	close, imageFile
	free_lun, outputFile, imageFile

end
