function dist, a, b
return, sqrt((float(a[0])-float(b[0]))^2 + (float(a[1])-float(b[1]))^2)
end

pro radialslope, imgFname, ns, nl, nb, out, psfile

cx = ns/2 & cy = nl/2		;; the center of the image

dfunction = dblarr(4096, nb+1)	;;this will hold the average value at each distance
				;; and the number of pixels at that distance

imgline = bytarr(nb, ns)	;;the current line of the image we are working with
openr, un, /get, imgFname	;;open the file

for i=0, nl-1 do begin
	readu, un, imgline	;;read one line at a time

	for j=0, ns-1 do begin
		cd = FIX(dist([j, i], [cx, cy]))	;;calc the distance from each point
							;; to the center of the image

;;once we know the distance add the pixel value to the dist function at dist
;; if the pixel is non-zero, add one to the count as well
		k = imgline(*,j)

		dfunction(cd, 0:nb-1) = dfunction(cd, 0:nb-1) + k
		if k(0) ne 0 then dfunction(cd, nb) = dfunction(cd,nb) + 1
	endfor
	if i mod 500 eq 0 then print, i
endfor

;;at this point we have a distance function set up to be the sum of pixels at a given
;;	distance, but there will be more pixels further from the center, so they need to
;;	be averaged
for i=0, nb-1 do begin
	dfunction(*,i) = dfunction(*,i)/dfunction(*,nb)
endfor

;; now we just plot up a few things to make it all look nice, and voila!


set_plot, 'ps'
;;among other things, sets the default font size, and filename
device,file= psfile ,xsize=7.5, ysize=10, xoff=.5, yoff=.5, /inches,$
	set_font='Times', /tt_font, font_size=14

line=dblarr(4096,nb, /nozero)
tmp = dblarr(4096, /nozero)
plot, dfunction(*,nb)
for i=0, nb-1 do begin
	top=max(where(dfunction(*,nb) ne 0))
	line(200:top-100,i) = dfunction(200:top-100,i)
endfor

plot, line(200:top-100,0), title='DN vs radial distance', xtitle='Distance from center', ytitle='average dn'
for i=1, nb-1 do begin
	oplot, line(200:top-100,i), linestyle=(i+1)
endfor

r=fltarr(2,nb)
for i=0, nb-1 do begin
	r(*,i) = linfit(indgen(n_elements(line(200:top-100,i))), line(200:top-100,i))
	print, r(*,i)
endfor

;result = regress(transpose(indgen(n_elements(line))), line, replicate(1, n_elements(line)), yfit, const, sigma, Ftst, Rvals)
;print, const, result
;print, 'R= ', Rvals

;xyouts,2000, 450,'Slope='+string(result, format='(f6.3)'), charsize=1.0
;xyouts,2000, 400,'R='+string(Rvals, format='(f6.3)') , charsize=1.0

;;and last let's save the data so we don't have to run through the whole thing again

openw, oun, /get, out
writeu, oun, dfunction
close, oun, un
free_lun, oun, un

end

;1.1
;r1       157.38047    -0.044202489
;r2       135.71454    -0.038650232
;r3       136.05322    -0.034395463

;combined
;r1c       171.23710    -0.050304402
;r2c       140.81946    -0.039632319
;r3c       143.29110    -0.035535828

