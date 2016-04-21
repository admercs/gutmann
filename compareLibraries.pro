PRO compareLibraries, lib1, lib2, outfile
  openr, un1, lib1, /get
  openr, un2, lib2, /get
  openw, oun, outfile, /get

  line1=''
  line2=''
  WHILE NOT eof(un1) DO BEGIN
     readf, un1, line1
     file=line1
     line1=file_basename(line1, "a")
     line1=file_basename(line1, "p")
     tmp=strsplit(line1, /extract)
     IF strlen(tmp[0]) EQ 2 $
       AND strmatch(tmp[0], "[0-9][0-9]") $
       AND n_elements(tmp) GT 1 THEN $
       line1=strjoin(tmp[1:n_elements(tmp)-1], ' ')

     WHILE NOT strcmp(line1, line2, /fold_case) $
       AND NOT eof(un2) DO BEGIN 
        readf, un2, line2
        line2=file_basename(line2, "p")
        line2=file_basename(line2, "a")
        tmp=strsplit(line2, /extract)
     IF strlen(tmp[0]) EQ 2 $
       AND strmatch(tmp[0], "[0-9][0-9]") $
       AND n_elements(tmp) GT 1 THEN $
          line2=strjoin(tmp[1:n_elements(tmp)-1], ' ')
     endWHILE


     
     IF NOT strmatch(line1, line2) THEN printf, oun, file
     point_lun, un2, 0
  ENDWHILE

  close, oun
  free_lun, oun

END
