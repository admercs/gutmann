pro pseudo_normalize,image1,ns,nl,th


;PURPOSE:  to perform a threshhold value processing on an existing
;          sam file.  A threshhold value is chosen and pixels that 
;          meet this criterium are located.  These pixels are then 
;          plotted against each other, a linear regression is done to
;          determine the slope and y-intercept that will correspond to
;          conversion/normalization factors.

;          Algorithm:
;          1)  read the sam pixel values
;          2)  determine where the pixels are that correspond to the 
;              given threshhold value
;          3)  plot these pixels against one another for the two images
;          4)  do a linear regression and get the m,b values
;          5)  use these values to do a normalization
;
;INPUT:  image1  -  the name of the sam image
;         ns     - number of samples, default is 4320
;         nl      - number of samples, default is 2983
;         th     - threshhold value, dafault is .01
;
;OUTPUT:  conversion factors to normalize an image to the base image.

!p.multi=[0,2,3]

if (n_elements(ns) eq 0) then ns=7497
if (n_elements(nl) eq 0) then nl=7253
if (n_elements(th) eq 0) then th=.01

base=''
normal=''
print,''
print,''
print,''
print,''
print,''
print,''
print,'For this program to work properly, the SAM image and the other'
print,'two images must be of the same dimensions.  They should already'
print,'meet this condition for the SAM to have been properly computed.'
print,''
print,'This program assumes you will be using an uncalibrated landsat 5, 6 band image'
print,''
read,base,PROMPT='What is the base image (the one you want to normalize to)?  '
read,normal,PROMPT='What is the image to be normalized?  '

openr, un1,/get,image1
openr, un2, /get, base
openr, un3,/get, normal
base_array=strcompress(image1+'base_array.dat')
normal_array=strcompress(image1+'normal_array.dat')
locations=strcompress(image1+'locations.dat')
 
 openw, un4, /get, locations
 openw, un5, /get, base_array
 openw, un6, /get, normal_array

 printf, un4, 'these are the locations of the pixels used as derived from the sam'


 ;number of bands
 nb = 6
 final_count=0

t1=systime(1)

line=fltarr(ns)
line3=bytarr(ns)
line2=bytarr(ns)
chierror=fltarr(6)
corrcoeff=fltarr(6)
hmmcoeff=fltarr(6)


for j=0, nb-1 do begin
  final_count=0
  

for i=0,nl-1 do begin

;read the sam and images file into an array

   readu, un1, line
   readu, un2, line2
   readu, un3, line3

;find the pixels that meet the threshhold criterium
  index = where (line le th,count)
  final_count=final_count + count
  if count gt 0 then begin
     if j eq 0 then begin
      printf, un4, 'line =',i+1
      printf, un4, 'sample =',index
     endif
     writeu, un5, line2(index)
     writeu, un6, line3(index)
  endif


endfor

    ;put the file pointer back at the beginnig of the sam file and repeat
    ;the process for the next band

;print, 'total number of pixels to be used in the normalization',final_count
    point_lun, un1, 0

endfor



point_lun,un5, 0
point_lun, un6,0


for j=0, 5 do begin

;put all of the pixels to be used in the normalization process into a 
;one dimensional array.  then plot it and get the statistics.


   base_pixel=bytarr(final_count)
   normal_pixel=bytarr(final_count)
   readu, un5, base_pixel
   readu, un6, normal_pixel

    ;if j eq 0 then help, base_pixel
    ;if j eq 0 then help, normal_pixel

;plot the values up

   !p.thick=2.0
   !p.charsize=2.0

   strng='Band'+string(j+1)
   if (j eq 5) then strng ='Band'+string(7)
	set_plot, 'ps'
   plot, normal_pixel,base_pixel,psym=1,title=strng,$
   xtitle='1985 image DN',ytitle='1996 Image DN',$
   xrange=[0,250],yrange=[0,250]


;do the linear regression and get the slope and y intercept
   result= linfit(normal_pixel,base_pixel,chisqr=chierr)
   regression,normal_pixel, base_pixel,w,a0,coeff,resid,yfit,$
          sigma,ftest,r,rmul,chisqr,/noprint
   chierror(j)=chierr
   corrcoeff(j)=r
   print, 'Coefficients of normalization for band',j+1
   print,'the fist value is the y-intercept, the second is the slope'
   print, result
   print, 'Correlation Coefficient'
   print, r
   print, ''



    x=bindgen(255)
    y=result(1)*x+result(0)
   oplot, x,y
   rtext=string(format='(f10.3)',r)
   rtext=strcompress('r='+rtext)
   xyouts,25,200,rtext,charsize=2.0


;find the standard deviations for each band.  this is necessary to do
; the normalization.


    base_stats=moment(base_pixel)
    normal_stats=moment(normal_pixel)

    ;print,'Standard deviation for base pixels',sqrt(base_stats(1))
    ;print,'Standard deviation for normalizing pixels',sqrt(normal_stats(1))

    ;print, 'Mean value for base pixels',base_stats(0)
    ;print, 'Mean value for normalizing pixels',normal_stats(0)


;Do a histogram matching technique to validate results from the regression

 ;  normal_matched=hist_match(normal_pixel, base_pixel)
      ;    pval1=hist_equal(normal_pixel,binsize=1./n_elements(normal_pixel),$
;		     /histogram_only)
;	pval2=hist_equal(base_pixel,binsize=1./n_elements(normal_pixel),$
;		/histogram_only)
;	   pval1=float(pval1)
;      pval2=float(pval2)
; pval1x=normal_pixel(sort(normal_pixel))
;	    size1=n_elements(pval1x)
;       pval1y=(findgen(size1)+1)/size1
;  pval2x=base_pixel(sort(base_pixel))

;     size2=n_elements(pval2x)
;pval2y=(findgen(size2)+1)/size2

  ;Multiply the data set to be normalized by its cdf and by the inverse
  ;of the base data set's.
;To do this we must interpolate for the x points of the normalizing data
    ;set in the base data set.
												      
;help, pval1x, pval2x, pval1y, pval2y
;pvalinterp=interpol(pval2y,pval2x,pval1x)
   
 ; help, pvalinterp
;  normal_matched=fltarr(2,n_elements(pvalinterp))

;   normal_matched(0,*)=pval1x
; normal_matched(1,*)=normal_pixel*pval1y/pvalinterp


   ;plot, pval1x, pval1y
   ;oplot, pval2x, pval2y
   ;plot, normal_matched(0,*), normal_matched(1,*), psym=1
   
 ;  help, base_pixel, normal_matched

   ;regression, normal_matched, w1, a01,coeff1, resid,$
	 ;yfit1,sigma,ftest, r1,rmul1,chisqr1

 ;   print, 'Coefficients for histogram matching regression'
   ; PRint, a01, coeff1
    ;hmmcoeff1(j)=coeff1
    ;oplot, base_pixel, yfit1,linestyle=2

endfor

 ;print,''
 ;print,''
 ;print, 'Chi squared error for the linear regression'
 ;print, chierror
 ;print, 'Correlation Coefficient for the linear regression'
 ;print, corrcoeff
 ;print, 'Correlation Coefficient for the histogram matching regression;'
 ;print, hmmcoeff1

save, file='stuff.dat'
   free_lun, un1,un2,un3,un4,un5, un6

end


 
