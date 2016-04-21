pro rgbClass, imgFile, outFile, ns, nl, type=type, jpeg=jpeg

;; assumes nb=3,r,g,b
r=0 & g=1 & b=2
nb=3

openw, oun, /get, outFile
outimg = bytarr(ns)

if not keyword_set(jpeg) then  begin
 if not keyword_set(type) then type = 1

 openr, un, /get, imgFile
 img=make_array(nb,ns,nl,type=type)
 for i=0, nl-1 do begin
    readu, un, img
 endfor
endif else $
 read_jpeg, imgFile, img

vegtot=long(0)
npvtot=long(0)
soiltot=long(0)
shadetot=long(0)
unknown=long(0)



;;NPV classification
	index = where((img(r,*)-img(g,*) ge 20) and (img(g,*)-img(b,*) ge-10))
	if (index(0) ne -1) then begin
		outimg(index) = 3
	endif

;;Green Veg Classification
	index = where(img(g,*) ge (img(r,*) + img(b,*))/2)
;;we can also stick a note in here fro blue grama if b>g
	if (index(0) ne -1) then begin
		outimg(index) =  7
	endif

;;Soil
	index = where((img(r,*)-img(g,*) ge 10) and (img(g,*)-img(b,*) le -10))
	if (index(0) ne -1) then begin
		outimg(index) = 15
	endif

;;Shade classification
	index = where(img(r,*) le 90)
	if (index(0) ne -1) then begin
		outimg(index) = 1
		shadetot=shadetot + n_elements(index)
	endif

	soiltot=soiltot+n_elements(where(outimg eq 15))
	vegtot=vegtot+n_elements(where(outimg eq 7))
	npvtot=npvtot+ n_elements(where(outimg eq 3))


	writeu, oun, outimg
	outimg(*)=0


tot=double(soiltot)+npvtot+vegtot + shadetot

print, imgFile
print, 'unknown=', float(ns)*nl - (float(soiltot) + shadetot + npvtot + vegtot)
print, 'soil=', soiltot, '%=', soiltot/tot
print, 'npv=', npvtot, '%=', npvtot/tot
print, 'veg=', vegtot, '%=', vegtot/tot
print, 'shade=', shadetot, '%=', shadetot/tot

close, un, oun
free_lun, un, oun

openw, oun, /get, string(outfile+'.res')
writeu, oun, soiltot, npvtot, vegtot, long(ns)*nl

end