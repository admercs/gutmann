FUNCTION pv_getnoons, data, day=day, ndays=ndays, modis=modis
  IF NOT keyword_set(day) THEN day=260
  IF NOT keyword_set(ndays) THEN ndays=5

  noons=fltarr(ndays)
  time=lindgen(n_elements(data))/48.0
  IF keyword_set(modis) THEN $
    noondex=where(time EQ day+(11/24.0)) $
  ELSE $
    noondex=where(time GT day+0.45 AND time LT day+0.70)

  FOR i=0, ndays-1 DO $
    noons[i] = mean(data[noondex+(i*48)])

  return, noons
END

PRO plotvarying
  dirs=file_search('*')
  !p.multi=[0,2,3]
  !p.charsize=2
  yr=[280,320]
  FOR i=0, n_elements(dirs)-1 DO BEGIN
     cd, current=maindir, dirs[i]
     files=file_search('out.*')
     filenum=intarr(n_elements(files))
     FOR j=0, n_elements(files)-1 DO $
        filenum[j]=fix((strsplit(files[j],'.',/extract))[1])
     files=files[sort(filenum)]
     junk=load_cols(files[0], data)
     plot, pv_getnoons(data[2,*]), yr=yr, title=dirs[i]

     FOR j=1, n_elements(files)-1 DO BEGIN
        junk=load_cols(files[j], data)
        oplot, pv_getnoons(data[2,*]), color=255*(float(j)/(n_elements(files)-1))
     ENDFOR
     cd, maindir
  ENDFOR        

END
