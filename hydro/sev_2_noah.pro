PRO sev_2_noah, filepattern, outputfile
  files=file_search(filepattern)
  IF files[0] EQ '' THEN BEGIN
     print, "File(s) not found : ", filepattern
     return
  ENDIF

  IF n_elements(outputfile) EQ 0 THEN outputfile='SEVUDS1'


  FOR i=0,n_elements(files)-1 DO BEGIN
     junk=load_cols(files[i], data)
     
; read the year out of a file named luis0x.txt
     year=fix(strmid(files[i], 4, 2))+2000
     
  ENDFOR


END

