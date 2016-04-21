;;calculates the average slope from the center of the image to the edge in dn
;; useful for correcting images taken with a flash camera on a rainy day
;; flat ground ends up with a circular patern of brightness.  This program plots
;; all points brightness vs distance from center (should use findcenter.pro) 

function dist, a, b
return, sqrt((a[0]-b[0])^2 + (a[1]-b[1])^2)
end



pro calcslope, imgFname, ns, nl, nb

cx = ns/2
cy = nl/2

openr, un, /get, imgFname
tmpimg = bytarr(nb,ns)
img = intarr(ns, nl, 2)

for i=0, nl-1 do begin
	readu, un, tmpimg
	img(*,i, 0) = total(tmpimg, 1)
endfor

for i=0, ns-1 do begin
	for j=0, nl-1 do begin
		img(i,j,1) = fix(dist([i,j], [cx,cy]))
	endfor
endfor

openw, oun, /get, string(imgFname + ".dist")
writeu, oun, img
free_lun, oun

j=max(img(*,*,1))
print, 'j=',j

tmp = bytarr(4096)
for i=0, 4095 do begin
	l=i
	t=i+1
	index = where((img(*,*,1) le t) and (img(*,*,1) ge l))
	if index(0) ne -1 then begin
		tmp(i) = mean(img(index))
	endif
endfor

print, tmp
a = linfit(tmp, indgen(512))
print, a

plot, tmp, psym=3


tmp = make_array(ns*nl, /byte, value=1)
result = regress(img(*,*,1), img(*,*,0), tmp, yfit, const, sigma, Ftst, Rvals)

print, 'fit= ', result, const
print, 'sigma= ', sigma
print, 'F-test= ',Ftst 
print, 'R = ', Rvals

end