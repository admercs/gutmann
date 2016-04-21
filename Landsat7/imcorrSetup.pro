pro fixfile, file, info, nns, nnl, outfile
  openr, un, file, /get
  openw, oun, outfile, /get
  
  data=bytarr(info.ns, info.nl)
  readu, un, data
  writeu, oun, data[0:nns-1, 0:nnl-1]

  close, oun, un
  free_lun, oun, un
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      Reads an enviheader file.
;;          returns a struct :
;;                  ns:number of samples in the file
;;                  nl:number of lines in the file
;;                  nb:number of bands in the file
;;                  map: an envi map structure (includes utm coords
;;                  and pixelsize)
;;                  desc: The description field in the .hdr
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function getFileInfo, name
  
  envi_open_file, name, r_fid=id
  
  if id eq -1 then return, {errorstruct, name:name, ns:-1, nl:-1, nb:-1}
  
  envi_file_query, id, nb=nb, nl=nl, ns=ns, h_map=maph, descrip=desc, $
    interleave=interleave, data_type=type
  HANDLE_VALUE, maph, map
  envi_file_mng, id=id, /remove
  
  return, {imagestruct, name:name, ns:ns, nl:nl, nb:nb, map:map, desc:desc, $
           interleave:interleave, type:type}
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      Sets envi header info (map and ns, nl, nb, type, interleave)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro setENVIHdr, info, fname
  envi_setup_head, fname=fname, ns=info.ns, nl=info.nl, nb=info.nb, $
    interleave=info.interleave, data_type=info.type, $
    descrip=info.desc, map_info=info.map, /write
end


pro subBand, infile, outfile, info
  if info.nb ge 3 then newband=2 else newband=0

  openr, un, /get, infile
  point_lun, un, info.ns*info.nl*info.type*newband
  
  tempdata=make_array(info.ns, info.nl, type=info.type)
  readu, un, tempdata
  close, un    &  free_lun, un

  openw, oun, /get, outfile
  writeu, oun, tempdata
  close, oun    & free_lun, oun

  info.nb=1
  setENVIHdr, info, outfile
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;       MAIN PROGRAM
;;
;;       Takes a reference/base map file and a file to be warped to
;;       the basemap (warp_file).  They should both be close to warped
;;       already.
;;
;;       Creates a script that will execture IMCORR on the two files.
;;       It will also resize the two files to have exactly the same
;;       number of samples and lines if they don't already.
;;
;;       Finally changes permisions on the script to executable and
;;       executes it.  
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro imcorrSetup, ref_File,warp_File_in

  envistart

;; prevents us from accidentally changing the file name in the calling
;; program too
  warp_File=warp_File_in  

  ref_info=getFileinfo(ref_File)
  warp_info=getFileinfo(warp_file)

  newns = min([ref_info.ns, warp_info.ns])
  newnl = min([ref_info.nl, warp_info.nl])

  oldrefFile = ref_File
  oldwarpFile = warp_File

  if ref_info.nb ne 1 then begin 
     print, 'ERROR : the reference image file ', ref_File, ' has more than one band'
     retall
  endif
  if warp_info.nb ne 1 then begin 
     print, 'Subseting ', warp_File, ' to a single band image for imcorr'
     print, '   into the file b3',warp_File
     print, '   the original file will remain untouched'
     subBand, warp_File, 'b3'+warp_File, warp_info
     warp_File = 'b3'+warp_File
  endif

;; we have to fix the number of samples or lines in the warp image only
  if newns ne warp_info.ns and newnl ne warp_info.nl then begin
     print, 'Changing size of : ', warp_File
     warp_File = 'preWarp'+warp_File
     fixfile, oldwarpFile, warp_info, newns, newnl, warp_File

     warp_info.ns = newns
     warp_info.nl = newnl

     setENVIhdr, warp_info, warp_File

;; we have to fix the number of samples or lines in the reference image only
  endif 
  if newns ne ref_info.ns and newnl ne ref_info.nl then begin
     print, 'Changing size of : ', ref_File
     ref_File = 'preWarp'+ref_File
     fixfile, oldrefFile, ref_info, newns, newnl, ref_File

     ref_info.ns = newns
     ref_info.nl = newnl

     setENVIhdr, ref_info, ref_File

  endif
  
;; open and write the batch imcorr file
  imcor='imcorrBatch'
  openw, un, /get, imcor
  printf, un, 'imcorr '+string(ref_File)+' '+string(warp_File)+' '+string(newns)+' '+string(newnl)+ ' '+oldwarpFile+'_imcorr.out >&'+oldwarpFile+'_imcorr.log'
  close, un

;; I don't know if this part will work on a PC, if not you can simply
;; execute the batch script from a command line by hand.  

; Makes file readable by all, read/write/executeable by the owner
  FILE_CHMOD, imcor, '0744'o  
  spawn, imcor

end

