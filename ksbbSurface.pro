FUNCTION ksbbSurface
  files=file_search("out.*")
  sz=strsplit(files[n_elements(files)-1], ".", /extract)
  sz=[fix(sz[3]), fix(sz[4])]+1
  print, sz

  err=fltarr(sz[0], sz[1])

  trueVal=sz/2
;; load in the "true" data values
  FOR i=0, n_elements(files)-1 DO BEGIN
     cursz=strsplit(files[i], ".", /extract)
     cursz=[fix(cursz[3]), fix(cursz[4])]

;; if this is the correct file then read the data
     IF cursz[0] EQ trueVal[0] $
       AND cursz[1] EQ trueVal[1] THEN BEGIN
        junk=load_cols(files[i], trueData)
;        i=n_elements(files) ; break out of the for loop
     ENDIF 
  ENDFOR 


  FOR i=0, n_elements(files)-1 DO BEGIN
     junk=load_cols(files[i], data)
     cursz=strsplit(files[i], ".", /extract)
     cursz=[fix(cursz[3]), fix(cursz[4])]
     err[cursz[0], cursz[1]]= max(data[2,*]-trueData[2,*])
  ENDFOR 
  
  surface, err
  return, err
END 
