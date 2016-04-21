PRO writeSoil, master, param, val
  openr, un, /get, master
  openw, oun, /get, "SOILPARM.TBL"
  line=""
  header=2

  FOR i=0, header DO BEGIN
     readf, un, line
     printf, oun, line
  ENDFOR

  readf, un, line
  current=strsplit(line, ",", /extract)
  current[param]=string(val)
  outline=current[0]
  FOR i=1, n_elements(current)-1 DO $
    outline=outline+", "+current[i]

  printf, oun, outline
  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     printf, oun, line
  ENDWHILE 
  
  close, oun, un
  free_lun, oun, un
END

PRO runNoah, val
  spawn, '../../bin/NOAH &>log'
  spawn, 'mv fort.111 out_'+strcompress(val, /remove_all)
END

PRO testSoils, master, param, min, max, n
  IF n_elements(master) EQ 0 THEN master = "masterSoil.txt"
  IF n_elements(param) EQ 0 THEN param = 1
  IF n_elements(min) EQ 0 THEN min = 1.
  IF n_elements(max) EQ 0 THEN max = 10.
  IF n_elements(n) EQ 0 THEN n = 70.

  inc=float(max-min)/float(n)

  FOR val=float(min), max, inc DO BEGIN
     writeSoil, master, param, val
;     if val mod 1 lt 0.1 then $
       print, val, (val-min)/(max-min)*100, " %", format="(F10.3,F5.1,A)"
     runNoah, val
  END
END

  
