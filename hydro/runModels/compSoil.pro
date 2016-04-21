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
  spawn, '../bin/NOAH >out'
  spawn, string('mv fort.111 ',outfile)  
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
  
  return, name
end


;; Run two different soil types specified default is standard IHOP
;; sand and clay.  
;; Runs NOAH and plots the standard output
pro compSoil, s1=s1, s2=s2

  if not keyword_set(s1) then s1=12
  if not keyword_set(s2) then s2=1

  writeStyp, s1
  outfile1=getName(s1)
  runNOAH, outfile1

  writeStyp, s2
  outfile2=getName(s2)
  runNOAH, outfile2

  makefigs, name1=outfile1, name2=outfile2

end
  
