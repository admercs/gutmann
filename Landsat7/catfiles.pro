;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Simple program searches through subdirectories for L7*0.tif files
;;   and concatenates all reflectance bands (1-5,7) into one bsq file
;;   with an ENVI .hdr file.  
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
  handle_value, maph, map
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Takes a list of files (one file for each band), opens each in ENVI
;;  and retreives the image data, then concatenates all the files
;;  together and outputs one file in Band Sequential format (BSQ)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION catBands, files
  
  FORWARD_FUNCTION ENVI_GET_DATA

  nfiles=n_elements(files)
;for all files, open in ENVI and cat together
  print, 'Reading data files...........'
  i=0
  ENVI_OPEN_DATA_FILE, files[i], r_fid=fid
  ENVI_FILE_QUERY, fid, ns=ns, nl=nl
  data=ENVI_GET_DATA(fid=fid, dims=[-1,0,ns-1,0,nl-1], pos=0)
  ENVI_FILE_MNG, id=fid, /remove
  
  for i=1,nfiles-1 do begin
     ENVI_OPEN_DATA_FILE, files[i], r_fid=fid
     ENVI_FILE_QUERY, fid, ns=ns, nl=nl
;;requires LOTS of RAM to perform efficiently
     tmp=ENVI_GET_DATA(fid=fid, dims=[-1,0,ns-1,0,nl-1], pos=0)
     data=[[[data]],[[tmp]]]
     ENVI_FILE_MNG, id=fid, /remove
  endfor


;generate new output file name from input filename
; original filename = L71ppprrryyyymmdd_Bx0.TIF
; output filename   = yyyy_mm_dd_ppp_rrr.bsq
  yearoffset=13
  ofname=strmid(files[0],yearoffset,4)+'-'+strmid(files[0],yearoffset+4,2)+'-'+ $
    strmid(files[0],yearoffset+6,2)+'_'+strmid(files[0],yearoffset-10,3) $
    +'_'+strmid(files[0],yearoffset-7,3)+'.bsq'

  print, ' '
  print, ' Now Creating : '
  print, ofname, '   from these files : '
  print, '-------------------------------------------'
  print, files
;OUTPUT concatenated file
  openw, oun, /get, ofname
  writeu, oun, data
  close, oun
  
;need to include map information...
;writeENVIhdr, ofname, ns=ns, nl=nl, nb=nfiles
  info=getFileInfo(files[0])
  info.nb=6                    ; we concatenated 6 bands
  info.interleave=0            ; BSQ format
  setENVIhdr, info, ofname

  return, ofname

end

pro FileToNDVI, fname, outfile
  info=getFileInfo(fname)
  bandsize=info.ns*info.nl*info.type
  
;; Read in bands 3 and 4 from the input file
  openr, un, /get, fname

;;skip over the first 2 bands
  point_lun, un, bandsize*2l
  
  b3=intarr(info.ns, info.nl)
  b4=intarr(info.ns, info.nl)
  readu, un, b3
  readu, un, b4

;; Calculate NDVI
  NDVI=byte( ((FLOAT(b4-b3)/FLOAT(b4+b3))>0) *255 )

;; Write NDVI to disk
  openw, oun, /get, outfile
  writeu, oun, NDVI

  close, un, oun
  free_lun, un, oun

;; write the ENVI header file for the NDVI image
  info.nb=1
  info.type=1
  info.desc='NDVI from reflectance file {OLD DESCRIPTION: '+info.desc+'}'

  setENVIhdr, info, outfile
end
  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   MAIN PROCEDURE
;;      Searches through one level of subdirectory and SCENE01
;;      directories within each subdirectory for files with names that
;;      match 'L7*1.tif'.  Chops off band8 if it exists and passes the
;;      list of file names in to the routine catBands
;;
;;   Starts ENVI in batch mode if is it not already running
;;     does not exit ENVI because IDL may be set to close with ENVI
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro catfiles, toNDVI=toNDVI, warp=warp, toRefl=toRefl, $
              baseImage=baseImage, delete=delete

  ENVI, /restore_base_save_files
  ENVI_BATCH_INIT

  filelist=findfile('*')
  nfiles=n_elements(filelist)
  for i=0,nfiles-1 do begin
     if file_test(strmid(filelist[i],0,strlen(filelist[i])-1), /directory) then $
       filelist[i]=strmid(filelist[i],0,strlen(filelist[i])-1)
     if file_test(filelist[i], /directory) then begin
        cd, filelist[i], current=olddir
        
        if file_test('SCENE01', /directory) then cd, 'SCENE01'
;find geotiff files
        L7files=findfile('L7*0.TIF')
;leave out band 8
        if n_elements(L7files) eq 7 then $
          L7files=L7files[0:5]
        if n_elements(L7files) eq 6 then begin
           print, "Found ", filelist[i]
           print, transpose(L7files)

           outfile=catBands(L7files)
           curfile=outfile
           
           if keyword_set(toRefl) then begin
              print, "Converting to Reflectance..."

              metafile = findfile('L7*_MTL.txt')
              curfile='refl_'+outfile
              L7torefl, outfile, metafile, curfile, /makebyte
              
              if keyword_set(delete) then $
                FILE_DELETE, outfile
           endif
           
           if keyword_set(toNDVI) then begin
              print, "Converting to NDVI..."
              FiletoNDVI, curfile, 'NDVI_'+outfile
              
              if keyword_set(delete) then $
                FILE_DELETE, curfile
              
              curfile='NDVI_'+outfile
           endif
           
           if keyword_set(warp) then begin
              print, "Warping..."
              if not file_test('w'+curfile) then $
                UTM13toUTM14, pattern=curfile, out='w'
              
              if keyword_set(delete) then FILE_DELETE, curfile
              curfile="w"+curfile
              
              if keyword_set(baseImage) then begin
                 print, "Combining Reference and Warp files..."
                 openw, oun, /get, 'combmeta'
                 printf, oun, '2'
                 printf, oun, olddir+"/"+baseImage
                 printf, oun, curfile
                 close, oun & free_lun, oun
                 combunequal, 'combmeta', "combined", /split
                 
                 newFile="comb_"+outfile
                 FILE_MOVE, "combined2", newFile, /overwrite
                 FILE_MOVE, "combined2.hdr", newFile+'.hdr', /overwrite
                 
                 print, "Running imcorr..."
                 imcorrSetup, "combined1", newFile
                 make_gcp_file, newFile+"_imcorr.out", newFile+"_imcorr.pts", 9, 1
              endif
           endif
        endif

;        FILE_DELETE, 'NDVI_'+outfile
        
        cd, olddir
     endif
  endfor
end
  
