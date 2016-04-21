;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Takes a texture name as input, an output filename, and an optional append keyword
;;
;;  Reads all out_texture_* files in the current directory and computes latent heat on day 626 (or 2)
;;
;;  Compiles the LE values for all files, and computes percentiles then outputs them to the outputfile
;;
;;  if the append keyword is set the output is appended to an existing output file.
;;  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRO SoilsWTextureStats, texture, outfile, append=append, varCol=varCol
  IF NOT keyword_set(varCol) THEN varCol =7
  files=file_search("out_"+strcompress(texture, /remove_all)+"_*")
  nfiles=n_elements(files)
  IF nfiles LT 3 THEN BEGIN
     print, "Not enought soils of type ", texture
     return
  ENDIF
  
  print, load_cols(files[0], data), files[0], $
         " 1 /",strcompress(nfiles)
  getDay=626
  IF n_elements(data[0,*]) LT 50000 THEN getDay=2
  index=where(fix(lindgen(n_elements(data[0,*]))/480.) EQ getDay)
  IF index[0] EQ -1 THEN return
  print, n_elements(index)
  n=n_elements(index)/2

  dat=mean(data[varCol,index])
  dat2=mean(data[varCol,index[n-10:n+10]])

  FOR i=1,n_elements(files)-1 DO BEGIN
     print, load_cols(files[i], data), files[i], $
            strcompress(i)," /",strcompress(nfiles)
     dat=[dat,mean(data[varCol,index])]
     dat2=[dat2,mean(data[varCol,index[n-10:n+10]])]
  endFOR

  print, min(dat), mean(dat)-stdev(dat), mean(dat), $
         mean(dat)+stdev(dat), max(dat)
;  print, percentiles(dat)
  print, percentiles(dat, value=reverse([0.99,0.95,0.75,0.5,0.25,0.05,0.01]))
  print, n_elements(dat)
  ndat=n_elements(dat)

  print, min(dat2), mean(dat2)-stdev(dat2), mean(dat2), $
         mean(dat2)+stdev(dat2), max(dat2)
;  print, percentiles(dat2)
  print, percentiles(dat2, value=reverse([0.99,0.95,0.75,0.5,0.25,0.05,0.01]))
  print, n_elements(dat2)
  ndat2=n_elements(dat2)

  openw, oun, /get, strcompress(texture, /remove_all)+".stat"
  printf, oun, dat, format='('+strcompress(ndat, /remove_all)+'F10.5)'
  printf, oun, dat2, format='('+strcompress(ndat2, /remove_all)+'F10.5)'
  close, oun
  free_lun, oun
  

  openw, oun, /get, outfile, append=append
  printf, oun, percentiles(dat, value=reverse([0.99,0.95,0.75,0.5,0.25,0.05,0.01])), n_elements(dat), format='(7F12.5,I5)'
  close, oun
  free_lun, oun
  openw, oun, /get, string(outfile,'2'), append=append
  printf, oun, percentiles(dat2, value=reverse([0.99,0.95,0.75,0.5,0.25,0.05,0.01])), n_elements(dat2), format='(7F12.5,I5)'
  close, oun
  free_lun, oun
END


