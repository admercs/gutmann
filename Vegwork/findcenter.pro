;; used to find the center of brightness around in an image.  
;;	vegetation pictures taken on a cloudy day will need a flash
;;	the flash distorts the image by making the center very bright,
;;	and the edges very dark.  

pro findcenter, imgFname, ns, nl, nb, outfile, psfile

openr, unin, /get, imgFname
img=bytarr(nb,ns)
fullim = intarr(ns,nl)
for i=0, ns-1 do begin
	readu, unin, img
	fullim(*,i) = total(img, 1)
endfor
img = byte(fullim/nb)
fullim = 0
free_lun, unin

;img = byte(total(img, 1)/nb)


;; compute an x-value based on the original image.  we can't do this for y because
;;	there is generally a tape measure running horizontally through the pictures, 
;;	which makes a huge spike when columns are summed.  
horspec = double(total(img, 2)/nl)
hor = double(0)
for i=0, ns-1 do begin
	hor = hor + (horspec(i) * (i+1))
endfor
hor = hor/(ns * mean(horspec))
plot, horspec


;; rotate image 45 degrees and plot the new vert and hor. histograms
;;	now we can compute a new center in both x and y without the tape measure

;;make the rotated image larger because it starts rectangular, and the short dimension
;;	chops out a lot of potentially  useful information.  
;rotimg = bytarr(ns,nl+2000)
;rotimg(*,1000:1000+nl-1) = img
rotimg = rot(img, 45)

sz1 = n_elements(rotimg(*,1))
d1spec = dblarr(sz1)
d1top = double(0)

for i=0, sz1-1 do begin
	d1spec(i) = total(rotimg(i,*))/n_elements(where(rotimg(i,*) ne 0))
	d1top = d1top + d1spec(i)*(i+1)
endfor
d1top = d1top/(sz1 * mean(d1spec))
print, d1top


sz2 = n_elements(rotimg(1,*))
d2spec = dblarr(sz2)
d2top = double(0)

for i=0, sz2-1 do begin
	d2spec(i) = total(rotimg(*,i))/n_elements(where(rotimg(*,i) ne 0))
	d2top = d2top + d2spec(i)*(i+1)
endfor
d2top = d2top/(sz2 * mean(d2spec))
print, d2top


;;if a postscript file was specified we will print it out here.  
if (n_parameters(0) eq 6) then begin
	set_plot, 'ps'
	;;among other things, sets the default font size, and filename
	device,file= psfile ,xsize=7.5, ysize=10, xoff=.5, yoff=.5, /inches,$
		set_font='Times', /tt_font, font_size=14

	plot, d1spec
	oplot, [d1top,d1top], [0,1000]

	plot, d2spec
	oplot, [d2top,d2top], [0,300]
	set_plot, 'x'
endif

if (n_parameters(0) ge 5) then begin
	openw, oun, /get, outfile
	writeu, oun, n_elements(d2spec), n_elements(d1spec), d2top, d2spec, d1top, d1spec
	print, 'outfile=', n_elements(d2spec), n_elements(d1spec), d2top, d1top
endif




x = d1top
y = d2top

;; but we need to rotate the "x,y" back into normal coordinates, so
;;	we will calculate the angle and distance between x,y and the center of
;;	rotation.  then we can subtract !pi/4 and find the real coordinates.  
;; currently this doesn't seem to work, sigh
cx = fix(sz1/2)
cy = fix(sz2/2)

real = rotPoint(x,y,cx,cy,(-!pi/4))

print, real
end


function rotPoint, x,y,cx,cy, angle

	dx = cx-x
	dy = cy-y
	d = sqrt((dx^2) + (dy^2))
	ac = acos(dx/d)
	as = asin(dy/d)
;	if dy ge 0 then begin
;		if dx ge 0 then begin
;			a = 2*!pi - a
;		endif
;	endif else begin
;		if dx ge 0 then begin
;			a = !pi + a
;		endif else begin
;			a = !pi - a
;		endelse
;	endelse
;
;a = a-!pi/2

	print, sin(as) *d
	print, cos(ac) *d
	print,'cx, cy, dx, dy', cx, cy, dx, dy
	print, x, y

	print, 'Original COSINE angle= ', float(ac/(2*!pi))*360
	ac = ac + angle
	print, 'New COSINE angle= ', float(ac/(2*!pi))*360

	print, 'Original SINE angle= ', float(as/(2*!pi))*360
	as = as + angle
	print, 'New SINE angle= ', float(as/(2*!pi))*360

	realx = fix(sin(as) * d)
	realy = fix(cos(ac) * d)
;;	realy = realy	;;  -1000 because we originally added 1000 before rotating

	print, 'distance = ', d
	
	print, 'realx = ', fix(realx)
	print, 'realy = ', fix(realy)



return, [realx, realy]
end

