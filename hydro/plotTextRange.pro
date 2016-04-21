PRO plotTextRange, input=input, output=output
  IF NOT keyword_set(input) THEN input="out*"
  IF NOT keyword_set(output) THEN output="textRange.ps"

  files=file_search(input, /test_regular)

  textNames=["sand", "loamy sand", "sa.loam", "si.loam", "silt", "loam", $
             "sa.cl.loam", "si.cl.loam", "cl.loam", "sa.clay", "si.clay", "clay"]
  textrange=fltarr(12, n_elements(files))
  var=12

  FOR i=0,n_elements(files)-1 DO BEGIN
     junk=load_cols(files[i], data)
     day=fix(strmid(files[i], strlen(input)-1, strlen(files[i])-strlen(input)+1))

     IF n_elements(days) EQ 0 THEN days=day ELSE days=[days,day]

     FOR texture=0,11 DO BEGIN
        index=where(data[1,*] EQ texture)
        IF index[0] NE -1 THEN BEGIN
           minmax=percentiles(data[var,index], value=[0.95,0.05])
           textrange[texture,i]=minmax[0]-minmax[1]
        endIF
     ENDFOR
  ENDFOR

  old=setupplot(filename=output)
  !p.multi=[0,1,2]
  !p.thick=3
  plot, days-365, textrange[0,*], yr=[0,500], $
        xtitle="Day of the year", ytitle="Latent Heat Range (W/m!U2!N)"
  j=0
  FOR i=0,11 DO BEGIN
     IF (where(textrange[i,*] GT 0))[0] NE -1 THEN BEGIN
        oplot, days-365, textrange[i,*], color=j+196
        oplot, [625.1,625.3]-365, [480-j*20,480-j*20], color=j+196
        xyouts, 625.4-365,480-j*20, charsize=0.5, $
                textNames[i]+" "+strcompress(n_elements(where(data[1,*] EQ i)))
        j++
     ENDIF
  ENDFOR


  resetplot, old
END

