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
;;	Sets envi header info (map and ns, nl, nb, type, interleave)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro setENVIhdr, info, fname
	envi_setup_head, fname=fname, ns=info.ns, nl=info.nl, nb=info.nb, $
		interleave=info.interleave, data_type=info.type, $
		descrip=info.desc, map_info=info.map, /write
end	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Reads filenames from a text file.  Filenames must be one to a line,
;; and the first file must be the
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function readGeoMeta, metafile
  openr, un, /get, metafile
  line=' '
  readf, un, line
  files=line
  while not eof(un) do begin
     readf, un, line
     if line ne '' then $ 
       files=[files,line]
  endwhile

  close, un  & free_lun, un
  
  nfiles=n_elements(files)
  return, {GeoFileInfo, n_warp:nfiles-1, ref_File:files[0], warp_Files:files[1:nfiles-1]}
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;    MAIN PROGRAM
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro GeoCorrectFiles, metafile, deleteExtras=deleteExtras
  envistart

  info=readGeoMeta(metafile)

;; First loop through all files converting to Zone 14 if necessary
  for i=0, info.n_warp-1 do begin
     hdrInfo=getFileInfo(info.warp_Files[i])

     if hdrInfo.map.proj.params[0] eq 13 then begin
        print, 'Converting file : ',info.warp_Files[i], ' to UTM zone 14'
        UTM13toUTM14, pattern=info.warp_Files[i], out='z14'
        info.warp_Files[i] = 'z14'+info.warp_Files[i]
     endif
  endfor

;; next write the input file for combunequal
  combFile='combunequalInput'
  combOutput='resized'

  openw, oun, /get, combFile
  printf, oun, info.n_warp+1
  printf, oun, info.Ref_File
  for i=0, info.n_warp-1 do $
     printf, oun, info.warp_Files[i]
  close, oun  & free_lun, oun
;; and run combunequal to resize them
  combunequal, combFile, combOutput, /split
  combOutput='resized'  ;combOutput gets Changed within combunequal :(

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subset out band 3 from each and use that for IMCORR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; First find the output files from combunequal
  resizedFiles=file_search(combOutput+'*.hdr')
  for i=0, n_elements(resizedFiles)-1 do $
    resizedFiles[i] = strmid(resizedFiles[i], 0, strlen(resizedFiles[i])-4)


;; and do a (very) little error checking
  if n_elements(resizedFiles) ne info.n_warp+1 then begin
     print, 'ERROR : Not the same number of resized files ('+ $
       strcompress(n_elements(resizedFiles), /remove_all)+') as initial files ('+ $
       strcompress(info.n_warp+1, /remove_all)+')'
     print, 'Resized Files : '
     print, resizedFiles
     print, 'Initial files to be warped : '
     print, info.warp_Files
     
     retall
  endif
  
;; now grab band3 from all files
  imcorrable=resizedFiles
  for i=0, n_elements(resizedFiles)-1 do begin
     newInfo=getFileInfo(resizedFiles[i])
     if newInfo.nb gt 2 then begin
        openr, un, /get, resizedFiles[i]
;; jump ahead to band 3
        point_lun, un, newInfo.ns*newInfo.nl*2*newInfo.type
;; read band3
        data=make_array(newInfo.ns, newInfo.nl, type=newInfo.type)
        readu, un, data
        
;; write b3 to a new file
        b3file='b3'+resizedFiles[i]
        openw, oun, /get, b3file
        writeu, oun, data
        close, un, oun & free_lun, un, oun
        
;; setup the necessary meta information
        newInfo.nb=1
        setENVIhdr, newInfo, b3file
        imcorrable[i]=b3file
     endif
  endfor
  ns = newInfo.ns
  nl = newInfo.nl

;; now run IMCORR on each file and warp with the output points
  for i=1, n_elements(imcorrable)-1 do begin
     
     
;; remember the first file is the reference file
;     imcorrSetup, imcorrable[0], imcorrable[i]
     spawn, STRING('imcorr ',imcorrable[0],' ',imcorrable[i],' ', $
                   ns,' ',nl,' ',imcorrable[i],'_imcorr.out');,' >', $
;                   imcorrable[i],'_imcorr.log')
     make_gcp_file, STRING(imcorrable[i],'_imcorr.out'), $
       STRING(imcorrable[i],'_imcorr.pts'), 9,3
     warpwithGCPs, resizedFiles[0], resizedFiles[i], $
       STRING(imcorrable[i],'_imcorr.pts'), $
       STRING('Warped_',info.warp_Files[i-1])
     if keyword_set(deleteExtras) then begin
        FILE_DELETE, imcorrable[i]
        FILE_DELETE, resizedFiles[i]
        if strmatch(info.warp_Files[i-1], 'z14*') then $
          FILE_DELETE, info.warp_Files[i-1]
     endif
  endfor

  if keyword_set(deleteExtras) then begin
     z14files=file_search('z14*')
     for i=0, n_elements(z14files)-1 do $
       FILE_DELETE, z14files[i]
  endif
  
end
