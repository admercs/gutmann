;; by default it creates a 512x512 image. ;; frequency should be in cycles / image.  ;; outfname is the output file namepro waveImage, outname, frequency, size=size, direction=direction	if not keyword_set(size) then size=512		img = bytarr(size, size)	gain = (2* 3.1415927) / (float(size) / frequency) print, gain	if direction eq 0 then begin		for i=0, size-1 do begin			img(i,*) = byte((100*sin(i*gain))+100);			print, i*gain, sin(i*gain), img(i,0);			wait, 0.01		endfor	endif else begin		for i=0, size-1 do begin			img(*,i) = byte(sin(i*gain) * 200)	;		print, img(0,i)		endfor	endelse		openw, oun, /get, outname	writeu, oun, img	free_lun, ounend	