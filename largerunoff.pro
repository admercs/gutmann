FUNCTION getrunoff, dir
  IF n_elements(dir) EQ 0 THEN dir='ihop8_0'
  
  cd, current=olddir, dir
  files=file_search('out_*')
  runoff=fltarr(n_elements(files))
  drain=fltarr(n_elements(files))
  soil=lonarr(n_elements(files))
  FOR i=0, n_elements(files)-1 DO BEGIN
     junk=load_cols(files[i], data)
     
     output=calcrunoff(data[*,0:500])
     
     precip=total(data[3,0:500]*1.79)
     
     runoff[i]=total(output.runoff)/precip
     drain[i]=abs(total(output.drain)/precip)
     soil[i]=(strsplit(files[i], '_', /extract))[2]
  endFOR
  cd, olddir
  return, {runoff:runoff, drain:drain, soil:soil}
END

PRO largerunoff
  files=file_search('ihop8_*')

;  FOR i=0, n_elements(files)-1 DO BEGIN
  i=n_elements(files)-1
     print, files[i]
     data=getrunoff(files[i])

     cd, current=olddir, files[i]
     openw, oun, /get, 'runoff'
     printf, oun, [data.soil, data.runoff, data.drain]
     close, oun
     free_lun, oun
     cd, olddir

;  ENDFOR
END


