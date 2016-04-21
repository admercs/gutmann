;;NOTE ENVI FILES MUST BE RESTORED BEFORE THIS WILL COMPILE!!
;;NOTE ENVI FILES MUST BE RESTORED BEFORE THIS WILL COMPILE!!
;;NOTE ENVI FILES MUST BE RESTORED BEFORE THIS WILL COMPILE!!
;;NOTE ENVI FILES MUST BE RESTORED BEFORE THIS WILL COMPILE!!
;;NOTE ENVI FILES MUST BE RESTORED BEFORE THIS WILL COMPILE!!

;; back when I apparently forgot how to write seperate procedures<smack>
;;	at least its commented.  from stats project


pro findEMs, avfile, emfile, outfile
nem=3
makenewfile = 0

tmpoutspec=outfile+strcompress(string(1), /remove_all)
tmpout=outfile+strcompress(string(2), /remove_all)

;;calculate statistics for the accuracy of an unmixing algorithm at 
;;	different endmembers, find the "best" endmembers in the scene
;;
;;	outfile - results...
;;	avfile - full resolution avris cube, optimum size & shape
;;		512, 512, 128, integer, bip
;;		Will work with other resolutions
;;	emfile - ascii file containing end member spectra (128 bands)
;;	nem - number of endmembers specified in emfile
;;	tmpout = temporary filename to save intermediate mf_doit type files to



;; initialization code for running in envi batch mode (redundant since this must
;;	occur before the program will compile anyways
envi_init, /batch_mode
envi_check_save, /spectral, /transform
;; we are now ready to run in envi batch mode.  this gives access to several key
;;	procedures in envi match_filter_mt_doit, envi_check_save, envi_get_data
;;	mnf_doit, envi_file_query, envi_open_file, envi_init, and envi_exit 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;open the file and get info (ns nl nb = 512, 512, 128)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
envi_open_file, avfile, r_fid=avfid
if avfid eq -1 then begin print, 'Could not open', avfile & return & endif

;;getinfo about the file (based on header info)
envi_file_query, avfid, ns=ns, nl=nl, nb=nb, data_type=dt, byte_order=bt, interleave=bi
fnb=nb	;;this is used later when we need to resample spectrally

;;the following are parameters to unmix_doit
pos=lindgen(nb)
dims=[-1l, 0, ns-1, 0, nl-1]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; av cub needs to have the bad (water) bands removed.  if the cube we
;;	were given already has155 bands, then the bad bands have been
;;	removed, else we need to remove them (call avsub_goodbands)
;;
;;	in either case we set up some initial parameters
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


if nb eq 155 then begin

	oldfile=avfile
	makenewfile = 1
	avfile=outfile+strcompress(string(3), /remove_all)
	openw, unnew, /get, avfile
	for o=0,nb do begin
		writeu, unnew, envi_get_data(dims=dims, fid=avfid, pos=o)
	endfor
	close, unnew
	free_lun, unnew

	envi_setup_head, file_type=0, interleave=bi, ns=ns, nl=nl, nb=nb, offset=0, $
		r_fid=avfid, fname=avfile, /write, data_type=dt

	envi_open_file, avfile, r_fid=avfid
	if avfid eq -1 then begin print, 'Could not open', avfile & return & endif
	print, 'opened'

	;;getinfo about the file (based on header info)
	envi_file_query, avfid, ns=ns, nl=nl, nb=nb, data_type=dt, byte_order=bt, interleave=bi
	fnb=nb	;;this is used later when we need to resample spectrally	

endif else if nb eq 224 then begin

	envi_file_mng, id=avfid, /remove
	makenewfile=1
	oldfile=avfile
	avfile=outfile+strcompress(string(3), /remove_all)
	avsub_goodbands, oldfile, avfile, ns=ns, nl=nl, nb=nb, bo=bi, dt=dt

	;; lets try this again
	envi_open_file, avfile, r_fid=avfid
	if avfid eq -1 then begin print, 'Could not open', avfile & return & endif

	;;getinfo about the file (based on header info)
	envi_file_query, avfid, ns=ns, nl=nl, nb=nb, data_type=dt, byte_order=bt, interleave=bi
	fnb=nb	;;this is used later when we need to resample spectrally

endif else begin
	print, 'Do not know how to deal with ', strcompress(nb), ' bands' 
	return
endelse

;;theoretically... actually we must be in bsq for a later section
case bi of
	0 : avimg=make_array(ns, nl, nb, type=dt)	;bsq
	1 : avimg=make_array(ns, nb, nl, type=dt)	;bil
	2 : avimg=make_array(nb, ns, nl, type=dt)	;bip
else: print'ERRORERRORERROR' & endcase & return 
endcase

;;the following are parameters to unmix_doit
pos=lindgen(nb)
dims=[-1l, 0, ns-1, 0, nl-1]


print, 'Mapping...'
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;calculate "true map" = full resolution map averaged to 2x2 (1x1?) grid
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

iendmem=fltarr(nb, nem)

for i1=0, ns-1 do begin
for i2=0, ns-1 do begin
for j1=0, nl-1 do begin
for j2=0, nl-1 do begin

if i1=i2 and j1=j2 then i2=(i2+1) mod ns	;;ensures we don't use 2 identical EMs

endmem[0]=avimg(i1,j1,*)
endmem[1]=avimg(i2,j2,*)
endmem[2]=avimg(i3,j3,*)
endmem[3]=avimg(i4,j4,*)
endmem[4]=avimg(i5,j5,*)
endmem[5]=avimg(i6,j6,*)

unmix_doit, $
	fid=avfid, $
	pos=pos, $
	dims=dims, $
	endmem=endmem, $
	r_fid=mapfid, $
	in_memory=0, $
	out_name=tmpout



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;retrieve "true map" from memory and calc Total End Memeber abundance
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
map=fltarr(ns,nl, nem+1)
for o=0, nem do begin
	tmap = envi_get_data(dims=dims, fid=mapfid, pos=o)
	map(*,*,o) = tmap
endfor

tmap=1
truEMabundance = fltarr(nem+1)

for i=0, nem do begin
	truEMabundance(i) = total(map(*,*,i))/(ns*nl)
endfor

envi_file_mng, id=mapfid, /remove
openw, outfid, /get, outfile




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;loop for all resolutions includeing full resolution
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;calculate how many iterations we need to loop for to get to 
;;	base values (~8bands, 1pixel, 8values)
spatialIterations	= Fix(alog(ns)/alog(2))
spectralIterations	= Fix(alog(nb)/alog(2)) - 2
radiometricIterations	= 9			;;assumes 4096->4

;; allocate memory for the "maps" we will create
EMabundance = fltarr(nem+1)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;	make a file to be used to temp store spectral character
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cavcub=intarr(ns,nl,nb)
for o=0, nb-1 do begin
	tcavcub=envi_get_data(dims=dims, pos=o, fid=avfid)
	cavcub(*,*,o)=tcavcub
endfor
tcavcub=1
envi_file_mng, id=avfid, /remove

cnb=nb

cavcub=cavcub(*,*,0:cnb-1)
openw, specun, /get,tmpoutspec
writeu, specun, cavcub
close, specun
free_lun, specun

cavcub=1	;;clears memory
pos=lindgen(cnb)
envi_setup_head, file_type=0, interleave=0, ns=ns, nl=nl, nb=cnb, offset=0, $
	r_fid=avfid, fname=tmpoutspec, /write, /open, data_type=dt

fendmem=endmem		;;fendmem=full endmember radiometry


print, 'Here we go...'
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;resize image spectrally, spatially, radiometrically (at end of loop)
for i=0, spatialIterations do begin			;;spatial resolution loop
	print, ns,nl
	for j=0, spectralIterations do begin		;;spectral resolution loop
		print, cnb
		for k=0, radiometricIterations do begin	;;radiometric resolution loop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;create "map" unmix_doit
unmix_doit, $
	fid=avfid, $
	pos=pos, $
	dims=dims, $
	endmem=endmem, $
	r_fid=mapfid, $
	in_memory=0, $
	out_name=tmpout


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;resample "map" to lowest resolution, compare to "true map"
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map=fltarr(ns,nl,nem+1)
for o=0, nem do begin
	tmap = envi_get_data(fid=mapfid, dims=dims, pos=o)
	map(*,*,o) = tmap
endfor
tmap=1
for l=0, nem do begin
	EMabundance(l) = total(map(*,*,l))/(ns*nl)
endfor

envi_file_mng, id=mapfid, /remove


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;write accuracy, spatial res, spectral res, radiometric res, %each EM
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
writeu, outfid, float(2^i),float(2^j),float(2^k),float(EMabundance), Float(truEMabundance)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;end loop this is where we really do all of the resampling
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;RADIOMETRIC RESAMPLEING
curAv = intarr(ns,nl,cnb)
for o=0, cnb-1 do begin
	tcurAv=envi_get_data(fid=avfid, dims=dims, pos=o)
	curAv(*,*,o) = tcurAv
endfor
tcurAv=1

envi_file_mng, id=avfid, /remove

curendmem=float(fix(curendmem/2))
curAv=curAv/2	;;this is all we need to do for radiometric resampleing
endmem=curendmem

envi_enter_data, curAv, r_fid=avfid

curAv=1		;;clear memory
endfor





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;SPECTRAL RESAMPLEING
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;need to read data from disk again to restore full radiometric resolution
;;data on disk should be spatially resampled already too

envi_file_mng, id=avfid, /remove
envi_open_file, tmpoutspec, r_fid=avfid
if avfid eq -1 then begin print, 'Could not open ', tmpoutspec, ns,nl,nb 
	help, name='*' & return & endif

curAv=intarr(ns,nl,cnb)
for o=0,cnb-1 do begin
	tcurAv=envi_get_data(fid=avfid, dims=dims, pos=o)
	curAv(*,*,o) = tcurav
endfor
tcurAv=1
envi_file_mng, id=avfid, /remove

cnb=cnb/2
for m=0, (cnb-1) do begin
	curAv(*,*,m) = (curAv(*,*,m*2)+curAv(*,*,m*2+1))/2
endfor

curAv = curAv(*,*,0:(cnb-1))

;; write data to a file to speed the next time
openw, specun, /get, tmpoutspec
writeu, specun, curAv
close, specun
free_lun, specun

;;reenter data to envi
curAv=1		;;clears memory
envi_setup_head, file_type=0, interleave=0, ns=ns, nl=nl, nb=cnb, offset=0, $
	r_fid=avfid, fname=tmpoutspec, /write, /open, data_type=dt

pos=lindgen(cnb)

;;resample endmembers
for m=0, (cnb-1) do begin
	fendmem(m,*) = float(fix((fendmem(m*2,*)+fendmem(m*2+1,*))/2))
endfor
endmem=fendmem(0:cnb-1, *)	;;restore radiometry of endmembers
fendmem=endmem
curendmem=endmem

endfor;;spectral resample for loop






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;again, need to read data from disk to restore full spectral resolution
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;SPATIAL RESAMPLEING
envi_file_mng, id=avfid, /remove
	
if ns ne 1 then begin


envi_open_file, avfile, r_fid=avfid
if avfid eq -1 then begin print, 'Could not open ', avfile & return & endif

curAv=intarr(ns,nl,nb)
for o=0,nb-1 do begin
	tcurAv=envi_get_data(fid=avfid, dims=dims, pos=o)
	curAv(*,*,o)=tcurAv
endfor
tcurAv=1

envi_file_mng, id=avfid, /remove

fendmem=iendmem		;;always spatially full endmem
endmem=fendmem		;;always radiometric full endmem
curendmem=endmem	;;resampled to hell endmem

cnb=fnb
ns=fix(ns/2)
nl=fix(nl/2)
dims=[-1l, 0, ns-1, 0, nl-1]
pos=lindgen(cnb)

for l=0, ns-1 do begin
for m=0, nl-1 do begin
	curAv(l,m,*) = (curAv(l*2, m*2, *) + curAv(l*2+1, m*2+1, *) + $
			curAv(l*2+1, m*2, *) + curAv(l*2, m*2+1, *)) /4
endfor
endfor
curAv = curAv(0:ns-1, 0:nl-1, *)

;;spectral resampleing will re-read from this file, we need to restore it too
openw, avun, /get, tmpoutspec
writeu, avun, curAv
close, avun
free_lun, avun
envi_setup_head, file_type=0, interleave=0, ns=ns, nl=nl, nb=nb, offset=0, $
	r_fid=avfid, fname=tmpoutspec, /write, data_type=dt


;;saves spatially resampled data to file and writes envi header
openw, avun, /get, avfile
writeu, avun, curAv
close, avun
free_lun, avun
envi_setup_head, file_type=0, interleave=0, ns=ns, nl=nl, nb=nb, offset=0, $
	r_fid=avfid, fname=avfile, /write, /open, data_type=dt
if avfid eq -1 then begin print, 'Could not reopen ', avfile, ns, nl, cnb & return & endif

endif
endfor	;;spatial for loop


;;delete all the tmp files we made while we were running
envi_open_file, tmpoutspec, r_fid=avfid
envi_file_mng, id=avfid, /remove, /delete
envi_open_file, tmpout, r_fid=avfid
envi_file_mng, id=avfid, /remove, /delete

;;if statement double checks that we don't delete the original file (bad)
if makenewfile eq 1 then begin
	envi_open_file, avfile, r_fid=avfid
	envi_file_mng, id=avfid, /remove, /delete
endif

close, outfid
free_lun, outfid

wait, 120

end
