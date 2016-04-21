function mse, array1, array2
; This function returns the Mean Square Error between the arrays
; Low MSE means that array1 and array2 are similar
  sse = 0.
  temp = (n_elements(array2) -1)
  for i=0, temp do $
    sse = sse + (array1(i) - array2(i))^2
  return, sse/n_elements(array2)
end


pro correct_l5, l5_in, l7_in, outfile, power
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; l5_in is a histogram of the Landsat 5 input image (*.hist)
; L7_in is a histogram of the Landsat 7 input image (*.hist)
; Use MAKE_HIST.PRO to generate the histograms for use in this program
;
; This program also uses LOAD_COLS.PRO and will not function without it
;
; outfile:
; outfile.ps is a postscript plot of the data.
;  x-axis is the correction value used on the Landsat 5 image
;  y-axis is the MSE between L5 and L7 for that correction value
;  The minimum y-value relates to the best correction ratio
;
; outfile-raw.corr is the formated raw data for outfile.ps
;  (so that it can be plotted in other programs)
;
; outfile-linfit.corr is a subset of the formated raw data (as found by FIND_EXTREMES)
;  This is output because its hard to fit an equation to all of the data, therefore
;  a subset is used, because its easier to fit an equation to just the part of the
;  data that were interested in
; outfile-ratios.corr is simply the correction ratios found for each band
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;cd, d:\users\peter\new crap I wont care about in a week
l5_in = '3134l5-best10k.hist'
l7_in = '3134l7-best10k.hist'
outfile = 'temp-crap'
power = 6


save=!p.multi
!p.multi=[0,2,3]
set_plot,'ps'
device,file=string(outfile+'.ps'),xsize=7.5, ysize=10, xoff=.5, yoff=.5, /inches
pstitles=['!17Band 1', 'Band 2', 'Band 3', 'Band 4', 'Band 5', 'Band 7']



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Loading in the histograms for each image
l5_cols = load_cols(string(l5_in), l5_raw)
l7_cols = load_cols(string(l7_in), l7_data)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; declaring some of the 10,000 data sets which will be used
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
poly_fits = dblarr(l5_cols, power+1)	; stores the polynomials used to fit the ploted data (subset data)
allmse = dblarr(1024, l5_cols)		; stores the MSE for each correction ratio and each band
corr_value = dblarr(l5_cols)		; stores the best correction ratio for each band
denominator = 255			; don't worry about this one, it is a constant
x_values = dblarr(1024)			; stores the correction values to use on L5
for i=0,1023 do $			; initialize x_array
  x_values(i) = (i+0.0)/255
l5_data=intarr(1024)			; corrected data from l5_raw
min_numerator =255			; temp value used until we find the best correction value
fewer_allmse_values = dblarr(200, l5_cols)
					; records MSE subset information for each band
fewer_x_values = dblarr(l5_cols, 201)
					; records the subseted x values for each band
					; the last array location [fewer_x_value(200)] stores the
					;  size of the subset, because it changes from band to band


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; this is just a little escape clause, in case we have a different number of bands
;;	probably this will never happen, but we might as well catch it if it does
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
if (l5_cols ne l7_cols) then return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;open all the files we are goin to write
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
openw, un1, string(outfile+'-raw.corr'), /get
openw, un2, string(outfile+'-linfit.corr'), /get
openw, un3, string(outfile+'-ratios.corr'), /get


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; this loop will do this entire process seperately for each band
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
for k=0, (l5_cols-1) do begin

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;here we set the worst case (the initial case) as our current best case (min MSE)
;; we will then proceed to test every other ratio and hopefully find the true best case
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	min_mse = mse(l5_raw(k,*), l7_data(k,*));;used for finding the best histofit
	minMSE=(Float(10)^12)*4			;;used for finding the best polyfit


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;this loop will test every l5:l7 ratio from 0/255 to 600/255
;;	to find the lowest MSE between l5*ratio and l7
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	for numerator=0, 600 do begin

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;initialize the variable for this step through the loop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		ratio = float(numerator)/denominator
		l5_data(*) = 0
		for i=0, n_elements(l5_raw(k,*))-1 do begin
			l5_data(round(i*ratio))=fix(l5_raw(k,i))
		endfor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; this is a little hack so that when we drop values 
;;	(because we are stretching the histogram) we fill in the
;;	dropped spaces with the value that is one higher, keeping
;;	histogram smooth so we don't get erroneously high MSE
;;	this will fail above a ratio of two, but we should be done then
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		index = where(l5_data eq 0)
		ind = index+1
		l5_data(index) = l5_data(ind)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; now we actually find the MSE associated with this ratio value
;;	and save it so we can graph all the MSE values at the end
;;	and find the minimum of the MSE curve
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		mean_sq_err = mse(l5_data(*), l7_data(k,*))
		allmse(numerator, k) = mean_sq_err

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;remember the numerator for the lowest MSE we find
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		if (mean_sq_err lt min_mse) then begin
			min_numerator = numerator
			min_mse = mean_sq_err
		endif
	endfor


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Now we know roughly the best ratio (min_numerator/255)
;;	and we have a plot of MSE values for all ratios (allmse)
;;	we will find the best polynomial fit to the data and use
;;	that to find the lowest point on the MSE curve... the
;;	true L7:L5 ratio we hope
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;begins to fit a polynomial to the data for a better correction value
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; We increment subset by 2 because we use subset/2 to
;;	reference arrays, which means odd might come out funny!!
	for sub_set=20,200,2 do begin
		allmse_plot_values = dblarr(sub_set)	; which will store the data to be
		x_plot_values = dblarr(sub_set)		; used in the poly_fit
		poly_value = dblarr(sub_set)
		fewer_x_values(k,200) = sub_set		;this is used to store the size
							;of the subset for later use



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Copying the data into these temp arrays
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		fewer_x_values(k,0:sub_set-1) =		x_values((min_numerator-sub_set/2):(min_numerator-1+sub_set/2))

		fewer_allmse_values(0:sub_set-1,k) =	allmse((min_numerator-sub_set/2):(min_numerator-1+sub_set/2), k)

		x_plot_values(0:sub_set-1) =		fewer_x_values(k,0:sub_set-1)

		allmse_plot_values(0:sub_set-1) =	fewer_allmse_values(0:sub_set-1, k)
		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; fits a polynomial to the data (it's important that the arrays passed in be the exact
;  size of the subset, so that zero-values (unused locations) do not affect the poly fit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		poly_value = poly_fit(x_plot_values(*), allmse_plot_values(*), power, /double)
		poly_fits(k,0:power-1) = poly_value(0:power-1)

		y_min = poly_value(0)

;make an array to compare allmse_plot_values with polyfit values
		curve_values=dblarr(sub_set)

;initialize ymin

		for p=1, power do $
			y_min = y_min+poly_value(p)*x_plot_values(0)^p
		curve_values(0)=y_min

		for n=1, sub_set-1 do begin

			y = poly_fits(k,0)+poly_fits(k,1)*fewer_x_values(k,n)+poly_fits(k,2)*fewer_x_values(k,n)^2+$
			poly_fits(k,3)*fewer_x_values(k,n)^3+poly_fits(k,4)*fewer_x_values(k,n)^4+$
			poly_fits(k,5)*fewer_x_values(k,n)^5

;;power = 6 but presumably it is fitting six coefficients, not 8...
;+poly_fits(k,6)*fewer_x_values(k,n)^6+$
;			poly_fits(k,7)*fewer_x_values(k,n)^7

			if (y lt y_min) then begin
				y_min = y
				x_min = x_plot_values(n)
			endif
			curve_values(n)=y
		endfor
		
;;now we check to see if this is the best polynomial fit we have had yet.  
		curMSE=mse(curve_values, allmse_plot_values)
		if minMSE gt curMSE then begin
			minMSE=curMSE
			best_sub_set=sub_set
		endif

	endfor	;;for loop that brings us through all sub_set sizes
	print, minMSE, curMSE
	print, best_sub_set

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; formating and outputing all the data into the three data output files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    corr_value(k) = (min_numerator + 0.0)/255
    print, '((Band '+strmid(string(k+1),7,1)+'))       Correction Ratio: '+$
	strmid(string(fix(round(x_min*255))),5,3)+'/255  = '+strmid(string(x_min),6,7)
;	Subset Area: '+strmid(string(sub_set),5,3)+$
;	' ('+strmid(string(extremes(1)),5,3)+'-'+strmid(string(extremes(0)),5,3)+ ') $ 

    printf, un3, 'Band '+strmid(string(k+1),7,1)+': '+string(fix(round(x_min*255)))+'/255   ='+string(x_min)
  endfor


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; outputing to file one
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  printf, un1, ''
  for index=0,1023 do begin
    tmp_str = ''
    tmp_str = string(x_values(index))
    for k=0,(l5_cols-1) do $
      tmp_str = tmp_str+'	'+string(allmse(index,k))
    printf, un1, tmp_str
  endfor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;outputing to file two
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  for index=0,sub_set-1 do begin
    tmp_str = ''
    for k=0,(l5_cols-1) do $
      tmp_str = tmp_str+'	'+string(fewer_allmse_values(index,k))
    if (k lt 6) then $
      tmp_str = string(fewer_x_values(k,index))+tmp_str
    printf, un2, tmp_str
  endfor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;outputing to file 3... but we're not?
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;openw, un3, /get, string(outfile+'.dat')
  ;writeu, un3, allmse


  for i=0, 5 do begin
    plot, x_values, allmse(*,i), psym=3, $
      xrange=[0,2], xtitle = 'Correction Ratio', /xstyle,  $
      ytitle = 'Mean Square Error',  $
      charsize=2.0, title = pstitles(i)
    ;oplot, fewer_x_values(i,*), fewer_allmse_values(*,i)
;    print, poly_fits(i,*)
    poly_value = dblarr(fewer_x_values(i,200))
    for y=0,fewer_x_values(i,200)-1 do begin
      for z=1, power do begin
        poly_value(y) = poly_value(y)+poly_fits(i,z)*fewer_x_values(i,y)^z
      endfor
    endfor
    for e=0, fewer_x_values(i,200)-1 do $
      x_plot_values(e) = fewer_x_values(i,e)
    oplot, x_plot_values, poly_value
;    oplot, fewer_x_values(i,*), poly_fits(i,0)+poly_fits(i,1)*fewer_x_values(i,*)+$
;      poly_fits(i,2)*fewer_x_values(i,*)^2+poly_fits(i,3)*fewer_x_values(i,*)^3+$
;      poly_fits(i,4)*fewer_x_values(i,*)^4+poly_fits(i,5)*fewer_x_values(i,*)^5+$
;      poly_fits(i,6)*fewer_x_values(i,*)^6
  endfor
  ;print, x_values

;print, dsf
  ;endfor
device,/close
close, un1, un2, un3
free_lun, un1, un2, un3
;set_plot, 'win'	;uncomment this if running on a Windows machine
set_plot, 'X" 	;uncomment this if running on a Unix machine
!p.multi = save	; restore original plot area
end
