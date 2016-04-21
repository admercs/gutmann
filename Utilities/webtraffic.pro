PRO webtraffic, key
  openr, un, /get, '/var/log/httpd/access_log'
  line=''
  tot=0.

  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     IF strmatch(line, key) THEN BEGIN 
        tmp=strsplit(line, /extract)
        tmp=tmp[n_elements(tmp)-1]
        tot=long(tmp)+tot
     ENDIF 
  ENDWHILE
  print, tot
  close, un
  free_lun, un
END

