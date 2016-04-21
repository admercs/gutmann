;;assumes single band files, originally written to plot NDVI histograms
;; landsat file should be the first img file

pro imgHisto, img1, img2, img3, ns, nl, plotFile

openr, imgUn1, /get, img1
openr, imgUn2, /get, img2
openr, imgUn3, /get, img3

imgarr1 = fltarr(ns,nl)
imgarr2 = fltarr(ns,nl)
imgarr3 = fltarr(ns,nl)

readu, imgUn1, imgarr1
readu, imgUn2, imgarr2
readu, imgUn3, imgarr3


;histo1 = histogram(imgarr1(where(imgarr1 ne 0)), binsize=0.01)
;histo2 = histogram(imgarr2(where(imgarr1 ne 0)), binsize=0.01)
;histo3 = histogram(imgarr3(where(imgarr1 ne 0)), binsize=0.01)

im1 = (imgarr1(where(imgarr1 ne 0)))
im2 = (imgarr2(where(imgarr1 ne 0)))
im3 = (imgarr3(where(imgarr1 ne 0)))


histo1 = fltarr(100)
histo2 = fltarr(100)
histo3 = fltarr(100)

j = 0.0
for j=0.0, .99, j+0.01 do begin
;for i=0, N_Elements(im1) do begin
	histo1(j*100) = total(im1 le j+0.01)-total(im1 le j)
	histo2(j*100) = total(im2 le j+0.01)-total(im2 le j)
	histo3(j*100) = total(im3 le j+0.01)-total(im3 le j)
endfor	

histo1 = histo1/100
histo2 = histo2/100
histo3 = histo3/100

;;saves and sets tickmarks to 2 sections per major interval
xminsave = !x.minor
yminsave = !y.minor
!x.minor = 1
!y.minor = 4

xthicksave = !x.thick
ythicksave = !y.thick
!x.thick=4
!y.thick=5

;;Sets system variables.  Setting !p.font to one selects for true type
fontsave=!p.font
!p.font=1
thicksave=!p.thick
!p.thick=2

set_plot, 'ps'

device,file= plotFile ,xsize=6, ysize=6.5, xoff=1.75, yoff=2.25, /inches, $
	set_font='Times', /tt_font, font_size=16

plot, histo1, xtitle='NDVI Value * 100', ytitle='Number of Occurences * 0.01'


oplot, histo2, linestyle=1
oplot, histo3, linestyle=2

xarr = [32, 43]
yarr = [710, 710]
oplot, xarr, yarr
yarr = [660, 660]
oplot, xarr, yarr, linestyle=1
yarr = [610, 610]
oplot, xarr, yarr, linestyle=2

xyouts, 45, 700, 'Landsat'
xyouts, 45, 650, 'AVIRIS'
xyouts, 45, 600, 'AVIRIS (BRDF corrected)'

device,/close
set_plot,'x'

!x.minor = xminsave
!y.minor = yminsave
!x.thick = xthicksave
!y.thick = ythicksave

!p.font = fontsave
!p.thick = thicksave

end