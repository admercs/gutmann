pro ungeo_byte, imgfname, ns, nl, nb, nloffset, gltfname, gltns, gltnl,ofname

; purpose: using an input .glt file, ungeocorrect an input image
;
; parameters:
;          imgfname - input image file name - must be BIP, byte values
;          ns, nl, nb - number of samples, lines, and bands for **ofname**
;          nloffset - the starting line of this image if it were to be part
;                     of the complete mosaic.  This is a 1-based value (i.e.
;                     the starting line of the second aviris cube in a mosaic
;                     would be 513).
;          gltfname - the .glt file 
;          gltns, gltnl - number of samples and lines for gltfname
;          ofname - output file name will be output in BIP, byte
;
;;NOTE	this program will not work for large files because it reads the ENTIRE output file
;;	into memory (or at least it needs that much space)
;;
;;also also NOTE the imgfile must be the same size and have the same offsets as the glt file
;;


;;nullspec = intarr(nb)
;;nullspec(*) = 0
spectrum = bytarr(nb)
gltline = intarr(gltns,2)
outfile = bytarr(nb, ns, nl)

outfile(*,*,*) = 0

openr,img_lun,/get, imgfname
openr,glt_lun,/get, gltfname
openw,outf_lun,/get, ofname

;;for k=0, nb-1 do begin
for i = 0,gltnl-1 do begin
  readu, glt_lun, gltline
   for j = 0,gltns-1 do begin
    if (gltline(j,0) ne 0 and gltline(j,1) ne 0) then begin

	x = ((abs(gltline(j,0)))-1)
	y = (((abs(gltline(j,1)))-(nloffset-1))-1)
	

	readu, img_lun, spectrum
	outfile(*, x,y) = spectrum
    endif else begin
	readu, img_lun, spectrum
    endelse
  endfor
endfor

writeu, outf_lun, outfile
;;free_lun, img_lun
;;openr, img_lun, /get, imgfname
;;free_lun, glt_lun
;;openr, glt_lun, /get, gltfname
;;endfor

free_lun, img_lun, glt_lun, outf_lun

end
