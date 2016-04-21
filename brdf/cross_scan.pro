pro cross_scan

;  This program uses the spectra taken from 8 stripes along
;  an AVIRIS image and ratios them against Landsat.
;  AVIRIS data must first be convolved to Landsat
;  4 FEB 00
;  Vegetation spectra is plotted as squares
;  Wheat Stubble Spectra is plotted as triangles
;  Pasture specra is plotted as diamonds
;  output plot named all.ps

;load wheat stubble spectra
print, load_cols ('av_wheat.spec',av_wheat)
print, load_cols ('l7_wheat.spec',l7_wheat)

;load pasture land spectra
print, load_cols ('av_all.spec',av_pasture)
print, load_cols ('l7_all.spec',l7_pasture)

;load vegetation spectra
print, load_cols ('av1.spec',av1)
print, load_cols ('av2.spec',av2)
print, load_cols ('av3.spec',av3)
print, load_cols ('av4.spec',av4)
print, load_cols ('av5.spec',av5)
print, load_cols ('av6.spec',av6)
print, load_cols ('av7.spec',av7)
print, load_cols ('av8.spec',av8)
print, load_cols ('l71.spec',l71)
print, load_cols ('l72.spec',l72)
print, load_cols ('l73.spec',l73)
print, load_cols ('l74.spec',l74)
print, load_cols ('l75.spec',l75)
print, load_cols ('l76.spec',l76)
print, load_cols ('l77.spec',l77)
print, load_cols ('l78.spec',l78)

;calculate ratios
veg_rat = fltarr(6,9)
veg_rat(*,1) = av1(1,*)/l71(1,*)
veg_rat(*,2) = av2(1,*)/l72(1,*)
veg_rat(*,3) = av3(1,*)/l73(1,*)
veg_rat(*,4) = av4(1,*)/l74(1,*)
veg_rat(*,5) = av5(1,*)/l75(1,*)
veg_rat(*,6) = av6(1,*)/l76(1,*)
veg_rat(*,7) = av7(1,*)/l77(1,*)
veg_rat(*,8) = av8(1,*)/l78(1,*)

pasture_rat = fltarr(6,9)  
for j=1,8 do begin
  pasture_rat(*,j) = av_pasture(j,*)/l7_pasture(j,*)
endfor

wheat_rat = fltarr(6,9)  
for j=1,8 do begin
  wheat_rat(*,j) = av_wheat(j,*)/l7_wheat(j,*)
endfor

;calculates slope and Y intercept for each set of spectra
stripe=indgen(8)+1
veg_slope=fltarr(6,2)
pasture_slope=fltarr(6,2)
wheat_slope=fltarr(6,2)

for k=0,5 do begin
  veg_slope(k,*)=linfit(stripe,veg_rat(k,1:8))
  pasture_slope(k,*)=linfit(stripe,pasture_rat(k,1:8))
  wheat_slope(k,*)=linfit(stripe,wheat_rat(k,1:8))
endfor

;;;;;;;;;;;;;;;;;;;;;;
;;section added by ethan to read ave ratio values too
;;;;;;;;;;;;;;;;;;;;;;
openr, avun, /get, '/sundog/scratch/fm99/brdfcorrection/ratiocalcimg/r3ate'
ave_slope = fltarr(6,2)
ave_rat = fltarr(6,9)
tmp = 0.0

for i=0, 5 do begin
	readu, avun, tmp
	ave_slope(i,0) = tmp

	readu, avun, tmp
	ave_slope(i,1) = tmp

	readu, avun, tmp
	ave_rat(i,8) = tmp
	readu, avun, tmp
	ave_rat(i,7) = tmp
	readu, avun, tmp
	ave_rat(i,6) = tmp
	readu, avun, tmp
	ave_rat(i,5) = tmp
	readu, avun, tmp
	ave_rat(i,4) = tmp
	readu, avun, tmp
	ave_rat(i,3) = tmp
	readu, avun, tmp
	ave_rat(i,2) = tmp
	readu, avun, tmp
	ave_rat(i,1) = tmp

	ave_slope(i,*) = linfit(stripe, ave_rat(i,1:8))

endfor
print, ave_slope

print, wheat_slope
print, veg_slope
print, pasture_slope

free_lun, avun
;;;;;;;;;;;;;;;;;;;;;
;; end most of ethan code
;;;;;;;;;;;;;;;;;;;;;


!p.multi=[0,2,3]

titles=['!17Band 1', $
           'Band 2', $
           'Band 3', $
           'Band 4', $
           'Band 5', $
           'Band 7']

;sets tic marks
!x.minor=1
!y.minor=1

set_plot, 'ps'
device, file = 'all.ps', xsize=8, ysize=10.5, xoff=0.25,$ 
 yoff=0.25,/inches

;sets font
;device,set_font='Times', /tt_font
fontsize=15
fontsave=!p.font
!p.font=1
thicksave=!p.thick
!p.thick=3

;set user defined symbol
  A=findgen(16)*(!pi*2/16.)
  usersym, cos(A), sin(A), /fill
  
for i=0,5 do begin
  plot,wheat_rat(i,*), xtitle=titles(i),xrange=[0,9],/xstyle, $
  ytitle='Ratio (AVIRIS/Landsat)',yrange=[.7,1.6],/ystyle, $
  charsize=2.2, psym=5, xthick=3, ythick=3, $
  xtickn=[' ','1','2','3','4','5','6','7','8',' '], xticks=9
  oplot, veg_rat(i,*), psym=6
  oplot, pasture_rat(i,*), psym=4
  oplot, ave_rat(i,*), psym=8

 ;plots the linfit slopes
  oplot,[.5,8.5],wheat_slope(i,1)*[.5,8.5]+wheat_slope(i,0)
  oplot,[.5,8.5],veg_slope(i,1)*[.5,8.5]+veg_slope(i,0) 
  oplot,[.5,8.5],pasture_slope(i,1)*[.5,8.5]+pasture_slope(i,0)
  oplot,[.5,8.5],ave_slope(i,1)*[.5,8.5]+ave_slope(i,0)


endfor
 
device, /close
set_plot, 'x'
 
end

