PRO commatospace, fname, outname
  IF n_elements(outname) EQ 0 THEN outname=fname+'.spc'

  line=''
  openr, un, /get, fname
  openw, oun, /get, outname

  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     printf, oun, strjoin(strsplit(line, ',', /extract), ' ')
  ENDWHILE

  close, oun, un
  free_lun, oun, un
end
