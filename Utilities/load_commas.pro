FUNCTION load_commas, filename, separator
  IF n_elements(separator) EQ 0 THEN separator=','
  line=''
  openr, un, /get, filename
  readf, un, line
  tmp=strsplit(line, ',', /extract)
  
  data=fltarr(n_elements(tmp), 10000)
  maxrows=10000
  point_lun, un, 0
  WHILE NOT eof(un) DO BEGIN 
     readf, un, line
  ENDWHILE
END

