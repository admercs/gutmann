function readSOIL
  openr, un, /get, 'SOILPARM.TBL'
  line=''
  header=3
  for i=1,header do readf, un, line

  readf, un, line
  dat=(float(strsplit(line, ',', /extract)))[0:10]
  
  while not eof(un) do begin
     readf, un, line
     dat=[[dat],[(float(strsplit(line, ',', /extract)))[0:10]]]
  endwhile

  close, un  & free_lun, un
  return, dat
end

