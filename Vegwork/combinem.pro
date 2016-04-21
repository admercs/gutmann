pro combinem, nimg, imgFnames, ans, anl, anb

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;initialize and declare all variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ns=ans(0)
nl=anl(0)
nb=anb(0)
tmpline=bytarr(nb,ns)
un=intarr(nimg)
linetot=lonarr(nb,ns, /nozero)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;open all necessary files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
for i=0, nimg-1 do begin
	openr, tmpun, /get, imgFnames(i)
	un(i)=tmpun
endfor
openw, oun, /get, 'combined'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;main loop, read a line from each file, sum and write them
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
for i=0, nl-1 do begin

	for j=0, nimg-1 do begin
		readu, un(j), tmpline
		linetot=linetot+tmpline
	endfor

	writeu, oun, linetot
	linetot(*,*)=0
endfor


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;close the files, and we should be done...
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
for i=0, nimg-1 do begin
	close, un(i), oun
	free_lun, un(i), oun
endfor

end