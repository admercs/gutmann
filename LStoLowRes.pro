pro LStoLowRes, lsimg, ns,nl,nb,pixSize, outfile

if not keyword_set(lsimg) then begin
	print, 'pro LStoLowRes, lsimg, ns,nl,nb,pixSize, outfile'
	return
endif

openr, un, /get, lsimg
openw, oun, /get, outfile

ratio=pixSize/30	;;ratio of new pixel size to old pixel size
curPix = bytarr(ratio)

newns=ns/ratio
oldns=newns*ratio	;;because we are going to need to drop ns mod ratio pixels
if ns mod ratio ne 0 then $
	endofline = bytarr(ns mod ratio)

newnl=nl/ratio
oldnl=newnl*ratio	;; same w/ nl mod ratio
if nl mod ratio ne 0 then $
	endofband = bytarr(ns * (nl mod ratio))

print, 'Samples = ', newns, 'Lines = ', newnl

newline = intarr(newns)
outline = bytarr(newns)


;;this is where we really do all the resampleing (ie averageing)
for band=0, nb-1 do begin
for i=0, newnl-1 do begin
for j=0, ratio-1 do begin
for k=0, newns-1 do begin

	readu, un, curpix
	newline(k) = newline(k) + fix(mean(curpix))

endfor;; all samples in one line

if ns mod ratio ne 0 then $
	readu, un, endofline

endfor;; lines in one newline

	outline = byte(newline / ratio)
	writeu, oun, outline
	newline(*) = 0

endfor;; all lines in one band

if nl mod ratio ne 0 then $
	readu, un, endofband

endfor;; all bands... we're done

close, oun, un
free_lun, oun, un

end