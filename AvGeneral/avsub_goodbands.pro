;; Remove the bad bands from an AVIRIS cube.  
;;
;;	avcubfile	= input aviris file
;;	outfile		= output file name
;;	ns		= optional number of samples, defaults to 614
;;	nl		= optional number of lines, defaults to 512
;;	nb		= optional number of bands, defaults to 224
;;	dt		= optional data type, 1=byte, 2=int, ...all idl types default=2
;;	bo		= optional bandorder, 2=bip, 1=bil, 0=bsq, default=2

pro avsub_goodbands, avcubfile, outfile, ns=ns, nl=nl, nb=nb, dt=dt, bo=bo

if not keyword_set(ns) then ns=614
if not keyword_set(nl) then nl=512
if not keyword_set(nb) then nb=224
if not keyword_set(dt) then dt=2
if not keyword_set(bo) then bo=2

case bo of
	2 : avcub=make_array(nb, ns, nl, type=dt)
	1 : avcub=make_array(ns, nb, nl, type=dt)
	0 : avcub=make_array(ns, nl, nb, type=dt)
	else: begin print, 'Bad Band Order Entered' + string(dt) & return & end
endcase


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	
;;	Read aviris cube and good band numbers
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
openr, avun, /get, avcubfile
readu, avun, avcub
close, avun
free_lun, avun

openr, wavun, /get, '~gutmann/idl/usewaves.wav'
waves=intarr(155)
readu, wavun, waves
close, wavun
free_lun, wavun

openw, outun, /get, outfile

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	
;;	Write subset
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

case bo of
	2 : writeu, outun, avcub(waves,0:511,*)
	1 : writeu, outun, avcub(0:511,waves,*)
	0 : writeu, outun, avcub(0:511,*,waves)
	else: begin print, 'Bad Band Order' & return &end ;; but we shouldn't get here
endcase

envi_setup_head, file_type=0, interleave=bo, ns=512, nl=nl, nb=155, offset=0, $
	r_fid=avfid, fname=outfile, /write, data_type=dt

close, outun
free_lun, outun


end
