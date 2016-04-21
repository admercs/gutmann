function dist, a, b
	return, sqrt((float(a[0])-float(b[0]))^2 + (float(a[1])-float(b[1]))^2)
end


pro FlashCorrect, imgFname, ns, nl, nb, slope, offset, outFile

cx = ns/2
cy = nl/2

curline = bytarr(nb, ns)
newline = intarr(nb, ns)
openr, un, /get, imgFname
openw, oun, /get, outFile

factor = indgen(4096)
fixer = fltarr(nb,4096, /nozero)
for i=0, nb-1 do begin
	fixer(i,*) = float(offset(i))/float(factor*slope(i) + offset(i))
endfor

for i=0, nl-1 do begin
	readu, un, curline
	for j=0, ns-1 do begin
		for k=0, nb-1 do begin
			newline(k,j) = FIX(curline(k,j) * (fixer(k, FIX(dist([j,i], [cx,cy])))))
		endfor
	endfor

	writeu, oun, newline	;;this will output in integer format!

	if i mod 200 eq 0 then print, i
endfor

close, oun, un
free_lun, oun, un

end
