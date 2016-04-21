PRO kickUnsat, programName, totFiles
  
  IF n_elements(totFiles) EQ 0 THEN totFiles=1482
  IF n_elements(programName) EQ 0 THEN programName='unsat'

  files=file_search('*')
  nfiles=n_elements(files)
  WHILE 1 EQ 1 DO BEGIN
     wait, 60
     line=''
     spawn, 'pslist unsat >pfile'
     openr, un, /get, 'pfile'
     WHILE NOT eof(un) DO BEGIN 
        readf, un, line
        data=strsplit(line, /extract)
        time=fix((strsplit(data[9], ':', /extract))[0])
        pid =fix(data[1])
        IF time GT 10 THEN BEGIN
           print, 'We Kickin it!'
           spawn, string('kill ', pid)
        ENDIF
        print, time, pid

     ENDWHILE
     close, un
     free_lun, un
  ENDWHILE

        
;     files=file_search('*')
;     nnfiles=n_elements(files)
;     IF nnfiles EQ nfiles THEN BEGIN
;        print, 'We Kickin it!'
;        spawn, string('/Users/gutmann/bin/killProcess ', programName)
;     ENDIF
;     print, nfiles, nnfiles
;     nfiles=nnfiles
;  ENDWHILE
END


     
