pro plotvscent, metafile

ns=1192
nl=708
nyr=11
nclasses=10

;agliv=fltarr(ns,nl,nyr)
;bgliv=fltarr(ns,nl,nyr)
;stded=fltarr(ns,nl,nyr)


agliv=[25.73, 20.65, 21.89, 19.94, 24.1, 17.79, 14.41, 19.81, 20.10, 28.03, 33.23]
;39.85, 42.7]
;bgliv=[123.11, 101.8, 135.45, 147.79, 148.03]
;stded=[11.81, 12.7, 14.55, 14.15, 8.32]


openr, unf, /get, full
openr, unc, /get, class

class=bytarr(ns,nl)
data=intarr(ns,nl,nyr)

readu, unf, data
readu, unc, class



save = !p.multi
!p.multi=[0,2,5]

;;saves and sets tickmarks to 2 sections per major interval
xminsave = !x.minor
yminsave = !y.minor
!x.minor = 1
!y.minor = 5

;;Sets system variables.  Setting !p.font to one selects for true type
fontsave=!p.font
!p.font=1
thicksave=!p.thick
!p.thick=2

set_plot, 'ps'

device,file= outfile ,xsize=7.5, ysize=10, xoff=.5, yoff=.5, /inches, $
	set_font='Times', /tt_font, font_size=14

tmpdat=intarr(ns,nl)
dat=intarr(nclasses,nyr, 2)
for i=0, nyr-1 do begin
	tmpdat=data(*,*,i)
	for j=0, nclasses-1 do begin
		index=where(class eq j+1)
		if index(0) ne -1 then begin $
			dat(j, i,0) = mean(tmpdat(index))
			dat(j, i,1) = stddev(tmpdat(index))
		endif else print, i,j,'no data!'
;		if index(0) eq -1 then print, i, j, 'no data'
	endfor
endfor

data=dat(*,*,0)
ldat=dat(*,*,0)-dat(*,*,1)
udat=dat(*,*,0)+dat(*,*,1)

for i=0, nclasses-1 do begin
	plot, agliv, data(i,*), xtitle='Century AGLiveC', ytitle='NDVI', psym=1, yrange=[0,2500]
	oplot, agliv, udat(i,*), psym=3
	oplot, agliv, ldat(i,*), psym=3
endfor

;for i=0, nclasses-1 do begin
;	plot, bgliv, data(i,*), xtitle='Century BGLiveC', ytitle='NDVI', psym=1
;endfor
;for i=0, nclasses-1 do begin
;	plot, stded, data(i,*), xtitle='Century StDead', ytitle='NDVI', psym=1
;endfor

device,/close
set_plot,'x'

!p.multi=save
!x.minor = xminsave
!y.minor = yminsave

!p.font = fontsave
!p.thick = thicksave



end

