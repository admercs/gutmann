function filterit, img, filter, ns, nl, xsz, ysz, w=w

;;these must be odd sized filters
if (xsz mod 2 eq 0) or (ysz mod 2 eq 0) then return, -1
tmpimg=intarr(ns, nl)
filimg=fltarr(ns, nl)

ave=1
xsz=fix(xsz/2)
ysz=fix(ysz/2)
if keyword_set(w) then begin
	tmpimg(where(img ge 50)) = 1
	tmpimg(where(img lt 50)) = 0
	ave=total(fix(filter))
endif else tmpimg=img

for i=xsz, ns-xsz-1 do begin
	for j=ysz, nl-ysz-1 do begin
		filimg(i,j)= float(total(float(tmpimg((i-xsz):(i+xsz), (j-ysz):(j+ysz))) $
				 * filter))/ave
	endfor
endfor

return, filimg

end




function dist, a, b
	a=float(a)
	return, sqrt(float((a(0)-b(0))^2) + (a(1)-b(1))^2)
end




function make_circle_filter, size

size=fix(size+2)

newfilter=intarr(size, size)

for i=0, size-1 do begin
	for j=0, size-1 do begin
		d=(fix(dist([i,j],[size/2, size/2])) - size/2)
		if abs(d) le 1  then $
			newfilter(i,j)=1
;		if d le -1 then $
;			newfilter(i,j)=-1
	endfor
endfor

return, newfilter

end;make_circle_array




;;finds crop circles about 15, 27, and 53 pixels wide, or finds circle_size wide
pro fndcrp, imgF, ns, nl, nb, outF, circle_size=circle_size, w=w

openr, unin, /get, imgF
img = bytarr(ns, nl, nb)
readu, unin, img
close, unin
free_lun, unin

openw, unout, /get, outF


sob=sobel(img)
tvscl, sob
for a=4, 16 do begin
	cs=a*2+1
	print, cs
	filter=make_circle_filter(cs)
	newimg=filterit(sob, filter, ns, nl, cs+2, cs+2, w=w)
	tvscl, newimg

	writeu, unout, newimg

endfor
tvscl, img

close, unout
free_lun, unout

end

