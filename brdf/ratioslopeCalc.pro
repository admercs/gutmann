;; takes the ratio of a landsat and an aviris image, then calculates the slope 
;;	across the image for all bands, assumes both are in BSQ format!
;;
;;	outputs a ps file of the plot
;;
;;	ethan gutmann 12/13/99

pro ratioslopeCalc, avfile, lsfile, ns, nl, nb, outfile, mask=mask, two=two

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

	if Keyword_set(mask) then begin
		index = where(lsband ne 0)


		deviation = mask
		avels = (total(Float(lsband(index)))/total(avband(index)))

		if deviation gt avels then begin 
			deviation = avels-0.1
		 endif
		print, 'Range = ', avels-deviation, avels, avels + deviation


;;;;;Diagnostics for deviation
;		if i ge 3 then deviation = 0.05
;
;		print, avels, ((total(Float(avband(index))))/n_elements(index)), $
;			 	((total(Float(lsband(index))))/n_elements(index))
;
;		print, avels - deviation, avels, avels+deviation
;
;		j = total(lsband(where( (Float(lsband(index)) / avband(index)) ge $
;				(avels + deviation))) ne 0)
;
;		k = where( (Float(lsband(index)) / avband(index)) le 0.3);$
;				(avels - deviation))
;		k = total(lsband(where( (Float(lsband(index)) / avband(index)) le $
;				(avels - deviation))) ne 0)
;
;		print, 'eq 0', $
;			n_elements(where( (Float(lsband(index))/avband(index)) eq 0))
;
;		print, '0 vals', n_elements(where(Float(lsband) eq 0))
;
;		print, 'deleted=',j+k
;		print, 'tot',(614.0*2560) - j - k, '	upper',j,'	lower', k
;		print, ''
;;;;;;end diagnostics

		if (total(where((Float(lsband(index))/avband(index)) le $
			(avels - deviation))) eq -1) OR $
			(total(where((Float(lsband(index))/avband(index)) ge $
			(avels + deviation))) eq -1) then begin
				print, 'No values in range, band', i+1
				stop
		endif

		lsband(where((Float(lsband(index))/avband(index)) le $
			(avels - deviation))) = 0
		lsband(where((Float(lsband(index))/avband(index)) ge $
			(avels + deviation))) = 0

	endif

	for j=0, ns-1 do begin
		
		index = where(lsband(j,*) ne 0)

		curline[j,i]=((total(lsband(j,index)) / total(lsband(j,index) ne 0))/ $
			(total(avband(j,index)) / total(avband(j,index) ne 0)))
	endfor

;;??does it matter wheather we use ls of av band here?
;; yes, av increases slope magnitude by up to 0.02, 
;; and y-intercept by up to 100.. which is actually "better"?  av?
	avels = total(lsband, 2) / total(lsband ne 0, 2)

	ave = total(avels, 1)/total(avels ne 0, 1)

	curline[*,i] = ave / curline[*,i]
endfor
close, avun, lsun
free_lun, avun, lsun

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Calculate the slope, y-intercept, and r values at each band
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

slope = fltarr(nb)
r = fltarr(nb)
const = fltarr(nb)


if Keyword_set(two) then begin
	for i=0, nb-1 do begin
	;	print, i
		slp = regress(transpose(indgen(200)), curline(0:199,i), $
				replicate(1.0, 200), $
				yfit, constval, sigma, ftst, rval)
		slope[i] = slp
		r[i] = rval
		const[i] = constval
	
	endfor
	Print, 'first 200 samples : slope, r, intercept'
	print, slope, r, const

	for i=0, nb-1 do begin
	;	print, i
		slp = regress(transpose(indgen(200)), curline(414:613,i), $
				replicate(1.0, 200), $
				yfit, constval, sigma, ftst, rval)
		slope[i] = slp
		r[i] = rval
		const[i] = constval
	
	endfor
	Print, 'last 200 samples : slope, r, intercept'
	print, slope, r, const

endif

for i=0, nb-1 do begin
;	print, i
	slp = regress(transpose(indgen(ns)), curline(*,i), $
			replicate(1.0, ns), $
			yfit, constval, sigma, ftst, rval)
	slope[i] = slp
	r[i] = rval
	const[i] = constval

endfor

title=['!17Band 1', $
           'Band 2', $
           'Band 3', $
           'Band 4', $
           'Band 5', $
           'Band 7']

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Plot ratio values as well as the best fit slope, R value, and y-intercept
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;save = !p.multi
;!p.multi=[0,2,3]

set_plot, 'ps'

device,file= outfile ,xsize=7.5, ysize=10, xoff=.5, yoff=.5, /inches

i=0
;for i=0, nb-1 do begin
plot, curline(*,i), psym=3, xtitle='!17Sample', ytitle='Ratio value', $
	charsize=2.0, xrange=[0,614], /xstyle, yrange=[0, 4000], /ystyle;, $
;	title= title[i] + '!C' +$
;	  strcompress(string(slope[i])) + strcompress(string(const(i))) + $
;	  strcompress(string(r[i]))
for i=1, nb-1 do begin
	oplot, curline(*,i)
endfor


set_plot, 'x'
;!p.multi = save

;openw, outun, /get, outfile 
;writeu, outun, curline
;close, outun
;free_lun, outun

PRINT, 'all samples : slope, r, intercept'
print, slope, r, const



end