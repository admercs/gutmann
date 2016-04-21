pro plot_bandscatter, avFname, lsFname, samples, lines, outFname

;;	avFname = Aviris file name
;;	lsFname = landsat file name
;;	samples = samples
;;	lines = lines
;;	outFname = output postscript file name
;;
;;	both aviris and landsat must be 6 band bsq files.  
;;	

;;open and read AVIRIS image file
openr,un1,/get, avFname
avimg=intarr(samples,lines,6)
readu,un1,avimg
free_lun,un1

;;open and read landsat image file
openr,un1,/get, lsFname
lsimg=intarr(samples,lines, 6)
readu,un1,lsimg
free_lun,un1

index = where(avimg(*,*,0) ne 0, okpix)

goodavpix = intarr(okpix, 6)
goodlspix = intarr(okpix, 6)


for j=0, 5 do begin
for i=0L, okpix-1 do begin
	goodavpix(i,j) = avimg((index(i) mod samples), $
				(index(i) / samples), $
				j)
	goodlspix(i,j) = lsimg((index(i) mod samples),$
				(index(i) / samples), j)
end
end



;; calculate various stats using regress instead of correlate
slp = fltarr(6)
cnst = fltarr(6)
rvals = fltarr(6)
for i=0, 5 do begin
	slope= regress(transpose(goodavpix(*,i)), goodlspix(*,i), $
		replicate(1.0,okpix), yfit, const, sigma, ftest, r)
	slp(i) = slope
	cnst(i) = const
	rvals(i) = r
end


;;create a line of best fit and a one to one line for plotting purposes
;;used to draw a line with a slope of one
oneToOne = intarr(2)
thisLine = intarr(2, 6)

oneToOne(0) = 0
oneToOne(1) = 5000

for i=0, 5 do begin
	thisLine(0, i) = cnst(i)
	thisLine(1, i) = cnst(i) + (slp(i) * 5000)
endfor


;;save !p.multi settings to be restored once we are done
;; p.multi lets us plot 6 graphs on one page
save=!p.multi
!p.multi=[0,2,3]

;;saves and sets tickmarks to 2 sections per major interval
xminsave = !x.minor
yminsave = !y.minor
!x.minor = 2
!y.minor = 2


;;Sets system variables.  Setting !p.font to one selects for true type
fontsave=!p.font
!p.font=1
thicksave=!p.thick
!p.thick=3


titles=['Band 1', $
           'Band 2', $
           'Band 3', $
           'Band 4', $
           'Band 5', $
           'Band 7']

set_plot,'ps'

;;amon other things, sets the default font size
device,file= outFname ,xsize=7.5, ysize=10, xoff=.5, yoff=.5, /inches,$
	set_font='Times', /tt_font, font_size=14

;;band 1
i=0
	plot,goodavpix(*,i),goodlspix(*,i),psym=3, $
		charsize=2.0, $	
		xrange=[0,5000],/xstyle, $
		yrange=[0,5000],/ystyle, $
		ytitle='Landsat reflectance * 10000', $
		title=titles[i]

	oplot, oneToOne, oneToOne, linestyle = 0
	oplot, oneToOne, thisLine(*, i), linestyle = 2

	xyouts,200, 4500,'Slope='+string(slp(i), format='(f6.3)'), charsize=1.0
	xyouts,200, 4000,'R='+string(rvals(i), format='(f6.3)') , charsize=1.0

i=i+1
	plot,goodavpix(*,i),goodlspix(*,i),psym=3, $
		charsize=2.0, $
		xrange=[0,5000],/xstyle, $
		yrange=[0,5000],/ystyle, $
		title=titles[i]

	oplot, oneToOne, oneToOne, linestyle = 0
	oplot, oneToOne, thisLine(*, i), linestyle = 2

	xyouts,200, 4500,'Slope='+string(slp(i), format='(f6.3)'), charsize=1.0
	xyouts,200, 4000,'R='+string(rvals(i), format='(f6.3)') , charsize=1.0

i=i+1
	plot,goodavpix(*,i),goodlspix(*,i),psym=3, $
		charsize=2.0, $
		xrange=[0,5000],/xstyle, $
		yrange=[0,5000],/ystyle, $
		ytitle='Landsat reflectance * 10000', $
		title=titles[i]

	oplot, oneToOne, oneToOne, linestyle = 0
	oplot, oneToOne, thisLine(*, i), linestyle = 2

	xyouts,200, 4500,'Slope='+string(slp(i), format='(f6.3)'), charsize=1.0
	xyouts,200, 4000,'R='+string(rvals(i), format='(f6.3)') , charsize=1.0

i=i+1
	plot,goodavpix(*,i),goodlspix(*,i),psym=3, $
		charsize=2.0, $
		xrange=[0,5000],/xstyle, $
		yrange=[0,5000],/ystyle, $
		title=titles[i]

	oplot, oneToOne, oneToOne, linestyle = 0
	oplot, oneToOne, thisLine(*, i), linestyle = 2

	xyouts,200, 4500,'Slope='+string(slp(i), format='(f6.3)'), charsize=1.0
	xyouts,200, 4000,'R='+string(rvals(i), format='(f6.3)') , charsize=1.0

i=i+1
	plot,goodavpix(*,i),goodlspix(*,i),psym=3, $
		charsize=2.0, $
		xrange=[0,5000],/xstyle, $
		yrange=[0,5000],/ystyle, $
		xtitle='Aviris reflectance * 10000', $
		ytitle='Landsat reflectance * 10000', $
		title=titles[i]

	oplot, oneToOne, oneToOne, linestyle = 0
	oplot, oneToOne, thisLine(*, i), linestyle = 2

	xyouts,200, 4500,'Slope='+string(slp(i), format='(f6.3)'), charsize=1.0
	xyouts,200, 4000,'R='+string(rvals(i), format='(f6.3)') , charsize=1.0

i=i+1
	plot,goodavpix(*,i),goodlspix(*,i),psym=3, $
		charsize=2.0, $
		xrange=[0,5000],/xstyle, $
		yrange=[0,5000],/ystyle, $
		xtitle='Aviris reflectance * 10000', $
		title=titles[i]

	oplot, oneToOne, oneToOne, linestyle = 0
	oplot, oneToOne, thisLine(*, i), linestyle = 2

	xyouts,200, 4500,'Slope='+string(slp(i), format='(f6.3)'), charsize=1.0
	xyouts,200, 4000,'R='+string(rvals(i), format='(f6.3)') , charsize=1.0


device,/close
set_plot,'x'

!p.multi=save
!x.minor = xminsave
!y.minor = yminsave

!p.font = fontsave
!p.thick = thicksave

end

