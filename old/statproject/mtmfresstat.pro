;;full avris MNF start =	3:40
;;stop				
;;stats start?
;;stop?
;;mtmf start
;;stop
;;

;;NOTE ENVI FILES MUST BE RESTORED BEFORE THIS WILL COMPILE!!
pro resstat, avfile, emfile, nem, outfile

;;calculate statistics for the accuracy of an unmixing algorithm at 
;;	different spatial, spectral, and radiometric resolutions
;;
;;	outfile - results for 2x2 grid
;;	avfile - the nearly full resolution avris cube, optimum size & shape
;;		512, 512, 128, integer, bip
;;		Will work with other resolutions
;;	emfile - ascii file containing end member spectra (128 bands)
;;	nem - number of endmembers specified in emfile

;; initialization code for running in envi batch mode (redundant since this must
;;	occur before the program will compile anyways
envi, /restore_base_save_files
envi_init, /batch_mode
envi_check_save, /spectral, /transform
;; we are now ready to run in envi batch mode.  this gives access to several key
;;	procedures in envi match_filter_mt_doit, envi_check_save, envi_get_data
;;	mnf_doit, envi_file_query, envi_open_file, envi_init, and envi_exit 


;;open the file and get info (ns nl nb = 512, 512, 128)
envi_open_file, avfile, r_fid=avfid
if avfid eq -1 then return

;;getinfo about the file (based on header info)
envi_file_query, avfid, ns=ns, nl=nl, nb=nb, data_type=dt, byte_order=bt, interleave=bi
;print, ns, nl, nb

;avcub=make_array(ns, nl, nb,type=dt)	;bsq format


;;NOTE ENVI FILES MUST BE RESTORED BEFORE THIS WILL COMPILE!!
;;might be possible to set pos=lindgen(nb) and do whole cube at once, see mnf_doit
dims=[-1l, 0, ns-1, 0, nl-1]
;for i=0, nb-1 do begin
;	avdat = envi_get_data(dims=dims, fid=avfid, pos=i)
;	print, n_elements(avdat)
;
;	avcub(*,*,i) = FLOAT(avdat)
;endfor

;;so we can run this on pcs or unix (though envi path needs changing)
if bt then byte_order, avcub

;;calculate "true map" = full resolution map averaged to 2x2 (1x1?) grid
pos=lindgen(nb-1)
outnb=30
mnf_doit, $
	fid=avfid, $
	pos=pos, $
	dims=dims, $
	r_fid = mnfid, $
	/in_memory, $		;;can store this in a file if memory is tight
	out_nb=outnb, $
	noise_evec=evec, $	;;unclear whether or not we need these noise info
	noise_eval=eval, $	
	noise_sta_name='somefilename.sta'

openr, emfid, /get, emfile
endmem=fltarr(nb, nem)
readu, emfid, endmem
free_lun, emfid

envi_stats_doit, $
	fid=mnfid, $
	pos=pos, $
	dims=dims, $
	mean = mean, $
	cov=cov, $
	evec=evec, $
	eval=eval, $ 
	comp_flag=4	;;4 sets bit 2 which says calc covariance matrix

match_filter_mt_doit, $
	fid=mnfid, $
	pos=pos, $
	dims=dims, $
	endmem=endmem, $
	mean=mean, $
	cov=cov, $
	evec=evec, $
	eval=eval, $
	out_dt=4, $
	r_fid=mapfid, $
	/in_memory



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;retrieve "true map" from memory and calc Total End Memeber abundance

pos2=lindgen(nem*2+2) 					;; +2?
map = envi_get_data(dims=dims, fid=mapfid, pos=pos2)
truEMabundance = fltarr(nem)

for i=0, nem do begin
	truEMabundance(i) = total(map(*,*,i))/(ns*nl)
endfor

envi_file_mng, mapfid, /remove
envi_file_mng, mnfid, /remove



openw, outfid, /get, outfile

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;loop for all resolutions includeing full resolution

;;calculate how many iterations we need to loop for to get to 
;;	base values (~8bands, 1pixel, 8values)
spatialIterations	= Fix(alog(ns)/alog(2)) + 1
spectralIterations	= Fix(alog(nb)/alog(2)) - 2
radiometricIterations	= 7			;;assumes 1024->8

;; allocate memory for each "map" we will create
EMabundance = fltarr(nem)
curendmem=endmem

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;resize image spectrally, spatially, radiometrically (at end of loop)
for i=0, spatialIterations do begin			;;spatial resolution loop
	for j=0, spectralIterations do begin		;;spectral resolution loop
		for k=0, radiometricIterations do begin	;;radiometric resolution loop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;perform mnf transform (mnf_doit)
mnf_doit, $
	fid=avfid, $
	pos=pos, $
	dims=dims, $
	r_fid = mnfid, $
	/in_memory, $
	out_nb=30, $
	/shift_diff, $
	sd_dims=dims

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;create "map" match_filter_mt_doit
envi_stats_doit, $
	fid=mnfid, $
	pos=pos, $
	dims=dims, $
	mean = mean, $
	cov=cov, $
	evec=evec, $
	eval=eval, $ 
	comp_flag=4	;;4 sets bit 2 which says calc covariance matrix

match_filter_mt_doit, $
	fid=mnfid, $
	pos=pos, $
	dims=dims, $
	endmem=curendmem, $
	mean=mean, $
	cov=cov, $
	evec=evec, $
	eval=eval, $
	out_dt=4, $
	r_fid=mapfid, $
	/in_memory
;;might need to specify output file


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;resample "map" to lowest resolution, compare to "true map"
map = envi_get_data(fid=mapfid, dims=dims, pos=pos2)

for l=0, nem do begin
	EMabundance(l) = total(map(*,*,l*2))/(ns*nl)
endfor


envi_file_mng, mapfid, /remove
envi_file_mng, mnfid, /remove


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;write accuracy, spatial res, spectral res, radiometric res, %each EM, infeasability
writeu, outfid, i, j, k, EMabundance, EMabundance/truEMabundance, total(map(*,*,nem*2+2))/(ns*nl)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;end loop this is where we really do all of the resampling

;;RADIOMETRIC RESAMPLEING
curAv=envi_get_data(fid=avfid, dims=dims, pos=pos)
envi_file_mng, avfid, /remove

curAv=float(curAv)/2

envi_enter_data, curAv, r_fid=avfid, dims=dims
endfor

;;need to read data from disk again to restore full radiometric resolution

envi_file_mng, avfid, /remove
envi_file_open
envi_open_file, avfile, r_fid=avfid
if avfid eq -1 then return

;;SPECTRAL RESAMPLEING
curAv=envi_get_data(fid=avfid, dims=dims, pos=pos)
envi_file_mng, avfid, /remove

for l=0, j do begin
	for m=0, (nb/2) do begin
		curAv(*,*,m) = (curAv(*,*,m*2)+curAv(*,*,m*2+1))/2
	endfor
endfor

nb = fix(nb/2)
if outnb gt nb then outnb=nb

newAv = Float(curAv(*,*,0:nb))
curAv=1					;;free memory of curAv

envi_enter_data, newAv, r_fid=avfid
pos=lindgen(nb)
endfor;;spectral resample for loop

;;again, need to read data from disk to restore full spectral resolution
;;SPATIAL RESAMPLEING
;;use envi's builtin spatial resampling?
envi_open_file, avfile, r_fid=avfid
if avfid eq -1 then return

curAv=envi_get_data(fid=avfid, dims=dims, pos=pos)
envi_file_mng, avfid, /remove

ns=fix(ns/2)
nl=fix(nl/2)
dims=[-1l, 0, ns-1, 0, nl-1]
newAv = fltarr
for l=0, ns/2 do begin
for m=0, nl/2 do begin
	curAv(l,m,*) = curAv	

endfor
envi_exit
end
