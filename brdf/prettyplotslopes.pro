pro prettyplotslopes, r2a, r2b, r3a, r3b, outfile

openr, r2aun, /get, r2a
openr, r2bun, /get, r2b
openr, r3aun, /get, r3a
openr, r3bun, /get, r3b

r2avals = fltarr(614, 6)
r2bvals = fltarr(614, 6)
r3avals = fltarr(614, 6)
r3bvals = fltarr(614, 6)

readu, r2aun, r2avals
readu, r2bun, r2bvals
readu, r3aun, r3avals
readu, r3bun, r3bvals



save = !p.multi
!p.multi=[0,2,1]

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

plot, r2avals(*,0), xtitle='Sample', ytitle='Average value', $
	xrange=[0,614], /xstyle, yrange=[0, 4000], /ystyle, $
	title='Run 2'
for i=1, 5 do begin
	oplot, r2avals(*,i)
endfor
for i=0, 5 do begin
	oplot, r2bvals(*,i), linestyle = 1
endfor


plot, r3avals(*,0), xtitle='Sample', ytitle='Average value', $
	xrange=[0,614], /xstyle, yrange=[0, 4000], /ystyle, $
	title='Run 3'
for i=1, 5 do begin
	oplot, r3avals(*,i)
endfor
for i=0, 5 do begin
	oplot, r3bvals(*,i), linestyle = 1
endfor


device,/close
set_plot,'x'

!p.multi=save
!x.minor = xminsave
!y.minor = yminsave

!p.font = fontsave
!p.thick = thicksave

end