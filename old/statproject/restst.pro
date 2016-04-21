;;NOTE ENVI FILES MUST BE RESTORED BEFORE THIS WILL COMPILE!!
;;NOTE ENVI FILES MUST BE RESTORED BEFORE THIS WILL COMPILE!!
;;NOTE ENVI FILES MUST BE RESTORED BEFORE THIS WILL COMPILE!!
;;NOTE ENVI FILES MUST BE RESTORED BEFORE THIS WILL COMPILE!!
;;NOTE ENVI FILES MUST BE RESTORED BEFORE THIS WILL COMPILE!!
pro restst, avfile, emfile, outfile
nem=3
makenewfile = 0

tmpoutspec=outfile+strcompress(string(1), /remove_all)
tmpout=outfile+strcompress(string(2), /remove_all)

;;calculate statistics for the accuracy of an unmixing algorithm at 
;;	different spatial, spectral, and radiometric resolutions
;;
;;	outfile - results for 2x2 grid
;;	avfile - the nearly full resolution avris cube, optimum size & shape
;;		512, 512, 128, integer, bip
;;		Will work with other resolutions
;;	emfile - ascii file containing end member spectra (128 bands)
;;	nem - number of endmembers specified in emfile
;;	tmpout = temporary filename to save intermediate mf_doit type files to



;; initialization code for running in envi batch mode (redundant since this must
;;	occur before the program will compile anyways
;envi, /restore_base_save_files
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
if avfid eq -1 then begin print, 'Could not open', avfile, ns, nl, nb & return & endif

;;getinfo about the file (based on header info)
envi_file_query, avfid, ns=ns, nl=nl, nb=nb, data_type=dt, byte_order=bt, interleave=bi
fnb=nb	;;this is used later when we need to resample spectrally

if nb eq 224 then begin
	envi_file_mng, id=avfid, /remove
	makenewfile=1
	oldfile=avfile
	avfile=outfile+strcompress(string(3), /remove_all)
	avsub_goodbands, oldfile, avfile, ns=ns, nl=nl, nb=nb, bo=bi, dt=dt

	;; lets try this again
	envi_open_file, avfile, r_fid=avfid
	if avfid eq -1 then begin print, 'Could not open', avfile, ns, nl, nb & return & endif

	;;getinfo about the file (based on header info)
	envi_file_query, avfid, ns=ns, nl=nl, nb=nb, data_type=dt, byte_order=bt, interleave=bi
	fnb=nb	;;this is used later when we need to resample spectrally
endif

;;the following are parameters to stats and match_filter
pos=lindgen(nb)
dims=[-1l, 0, ns-1, 0, nl-1]

;;so we can run this on pcs or unix (though envi path needs changing)
;if bt then byte_order, avcub


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;calculate "true map" = full resolution map averaged to 2x2 (1x1?) grid
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
openr, emfid, /get, emfile
iendmem=fltarr(nb, nem)
readu, emfid, iendmem
free_lun, emfid
endmem=iendmem
initendmem=endmem

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
map=fltarr(ns,nl, nem)
for o=0, nem-1 do begin
	tmap = envi_get_data(dims=dims, fid=mapfid, pos=o)
	map(*,*,o) = tmap
endfor
tmap=1
truEMabundance = fltarr(nem)

for i=0, nem-1 do begin
	truEMabundance(i) = total(map(*,*,i))/(ns*nl)
endfor

envi_file_mng, id=mapfid, /remove

print, map(0:9,0:9,*)
print, mean(map(*,*,0)), mean(map(*,*,1)), mean(map(*,*,2)) 

end