FUNCTION getfnames, file
  openr, un, /get, file
  output=""
  readf, un, output
  WHILE NOT eof(un) DO BEGIN
     line=""
     readf, un, line
     output=[output, line]
  ENDWHILE
  close, un
  free_lun, un
  return, output
enD

PRO RS_KW_test, filenamelist
  files=getFnames(filenamelist)
  nfiles=n_elements(files)
  
  data=fltarr(nfiles, 1000)
  data[*]=-9999

  FOR i=0, nfiles-1 DO BEGIN
     openr, un, files[i]+".stat", /get
     line=""
     readf, un, line
     tmp=float(strsplit(line, /extract))
     data[i,0:n_elements(tmp)-1]=tmp
     close, un
     free_lun, un
  endFOR
  
  print, kw_test(data, missing=-9999)
  print, kw_test(data[8:10,*], missing=-9999)
  print, kw_test(data[4:7,*], missing=-9999)
  print, kw_test(data[2:nfiles-1,*], missing=-9999)
  print, kw_test(data[2:nfiles-1,*], missing=-9999)
  
  results=fltarr(2,nfiles, nfiles)
  FOR i=0, nfiles-1 DO BEGIN 
     FOR j=0,nfiles-1 DO BEGIN 

        IF i NE j THEN begin
           idex=where(data[i,*] NE -9999)
           jdex=where(data[j,*] NE -9999)
           results[*,i,j]= $
             rs_test(transpose(data[i,idex]), transpose(data[j,jdex]))
        endIF

     endFOR
  ENDFOR
  print, reform(results[1,*,*], nfiles,nfiles), $
         format='('+strcompress(nfiles,/remove_all)+'F6.3)'
  print, ""
  print, '10 percent'
  print, reform(results[1,*,*], nfiles,nfiles) GT 0.1
  print, ""
  print, '5 percent'
  print, reform(results[1,*,*], nfiles,nfiles) GT 0.05
  print, ""
  print, '1 percent'
  print, reform(results[1,*,*], nfiles,nfiles) GT 0.01

end
