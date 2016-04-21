FUNCTION readSoilText, fname
  line=''
  header=2
  dat=[0.,0,0]
  nlines=0

  openr, un, /get, fname
  for i=1,header do readf, un, line

  while not eof(un) do begin
     j=0
     readf, un, line
     j=strsplit(line, /extract)
     sz=n_elements(j)
     dat=[[dat],[float(j[sz-3:sz-1])]]
     nlines++
  endwhile

;; chop off the initial dummy value
  dat=dat[*,1:nlines]

;; file cleanup
  close, un  &  free_lun, un

  return, dat
end
