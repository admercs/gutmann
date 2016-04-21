PRO Find_Replace, fname, find, replace, outputfile

  openr, un, /get, fname
  openw, oun, /get, outputfile
  line=""
  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     tmp=strsplit(line, /extract)
     FOR i=0,n_elements(tmp)-1 DO $
       IF tmp[i] EQ find THEN tmp[i]=replace
     printf, oun, tmp
  ENDWHILE 
  close, un, oun
  free_lun, un, oun

END 
  
