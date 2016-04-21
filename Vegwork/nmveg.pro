function classImage, image

	R=0
	G=1
	B=2
	Error = -1

	sz=size(image)
	result=bytarr(sz(2),sz(3))
	ave=(long(image(R,*,*))+image(G,*,*)+image(B,*,*))/3

;	npv=where((image(R,*,*)-image(G,*,*)) gt Error and $
;		(image(G,*,*) -image(B,*,*)) gt Error and $
;		ave gt 100)
	soil=where((image(R,*,*)-image(G,*,*)) gt Error and $
		ave gt 100)
	veg=where((image(G,*,*)-image(R,*,*)) gt Error); and $
;		(image(B,*,*)-image(G,*,*)) gt Error and $
;		ave gt 20 and ave lt 150)

	shade=where(ave lt 25)
	tape=where(ave gt 220)

;	if npv(0) ne -1 then $
;		result(npv)=10

	if veg(0) ne -1 then $
		result(veg)=4

	if soil(0) ne -1 then $
		result(soil)=8

	if shade(0) ne -1 then $
		result(shade)=0

	if tape(0) ne -1 then $
		result(tape)=1

	print, ' tape',n_elements(tape),' shade',n_elements(shade),' veg',n_elements(veg),$
		' npv',n_elements(npv),' soil',n_elements(soil)

	return, result
end




pro nmveg, delay=delay, suffix=suffix, prefix=prefix

if not keyword_set(suffix) then suffix = '.jpg'
if not keyword_set(prefix) then prefix = '*'
if not keyword_set(delay) then delay=2

list= findfile(prefix+'*'+suffix)

if list(0) ne '' then $
  for i=0,n_elements(list)-1 do begin
	read_jpeg,list(i), image
	print, float(i)/n_elements(list) * 100
	classed = classImage(image)

	full=float((size(classed))(1) * (size(classed))(2))
	print, 	'Veg%=', n_elements(where(classed eq 4))/full, $
		' NPV%=', n_elements(where(classed eq 10))/full, $
		' Soil%=', n_elements(where(classed eq 8))/full

	tvscl,image,true=1, 0
	tvscl, classed, 1
	wait, delay

	outfile=list(i)+'.out'
	openw, un, /get, outfile
	nl=(size(classed))(2)
	for j=1,nl do begin
		writeu, un, classed(*,nl-j)
	endfor

	close, un
	free_lun, un
  endfor


end



