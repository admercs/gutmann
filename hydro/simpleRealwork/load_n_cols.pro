FUNCTION load_n_cols, n, fname, header=header, double=double, separator=separator
  openr, un, /get, fname
  line=''
  IF NOT keyword_set(separator) THEN separator=' '
  IF NOT keyword_set(header) THEN header=0
  IF keyword_set(double) THEN data=dblarr(n, 10000) ELSE data=fltarr(n,10000)

  FOR i=0, header-1 DO readf, un, line
  i=-1
  WHILE NOT eof(un) DO BEGIN
     i++
     readf, un, line
     tmp=strsplit(line, separator, /extract)
     IF keyword_set(double) THEN data[*,i] = double(tmp[0:n-1]) $
     ELSE data[*,i] = float(tmp[0:n-1])

     IF i+1 GE n_elements(data[0,*]) THEN $
       data=[[data],[data]]
  ENDWHILE

  data=data[*,0:i]
  close, un
  free_lun, un
  return, data
END

