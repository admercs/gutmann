;; Run two different soil types specified default is standard IHOP
;; sand and clay.  
;; Runs NOAH and plots the standard output


;; write the IHOPstyp file
pro writeStyp, soil
  openw, oun, /get, 'IHOPstyp'

  printf, oun, 'Site'
  printf, oun, '1       2       3       4       5       6       7       8       9'
  printf, oun, strcompress(soil)

  close, oun  &  free_lun, oun
end


;; run the NOAH model
pro runNoah, outfile
  spawn, './noah >out'
  spawn, string('mv out.* ''',outfile,'''')  
end


;; read in the SOILPARM file and return the name that matches the soil number
function getname, soil
  openr, un, /get, 'SOILPARM.TBL'
  line=''
;; skip the header
  readf, un, line  & readf, un, line  & readf, un, line
  done=0
  while not eof(un) and not done do begin
     readf, un, line
     name=strsplit(line, ',', /extract)

     if fix(name[0]) eq soil then begin
        name=strcompress(name[11], /remove_all)
        name=strmid(name, 1, strlen(name)-2)
        done=1
     endif

  endwhile
  close, un  & free_lun, un
  
  return, name
end


;; Run every soil type from 1 to last(default=21)
;; Runs Noah for all soils and saves the name of the output files in a file
;;   named "fileList"
PRO allSoils, last, clean=clean
  IF N_elements(last) EQ 0 THEN last = 12

  openw, oun, /get, 'fileList'

  FOR s1=1, last DO BEGIN
     IF keyword_set(clean) THEN BEGIN
        spawn, "rm "+''''+getName(s1)+''''
     ENDIF ELSE BEGIN 
        writeStyp, s1
        outfile=getName(s1)
        print, 'Working on ', outfile, '...'
        runNOAH, outfile
        printf, oun, outfile
     ENDELSE 
  ENDFOR

  close, oun  & free_lun, oun

END
  
PRO wetDryAll, last
  line=" "
  spawn, "cp IHOPUDS1wet IHOPUDS1"
  allSoils, last

  openr, un, /get, "fileList"
  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     spawn, string('mv ''',line,''' ''',line,'.wet''')  
  ENDWHILE 
  close, un  & free_lun, un

  spawn, "cp IHOPUDS1dry IHOPUDS1"
  allSoils, last
  openr, un, /get, "fileList"
  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     spawn, string('mv ''',line,''' ''',line,'.dry''')  
  ENDWHILE 
  close, un  & free_lun, un

END 
