FUNCTION calcStats, files, varCol=varCol, exclude=exclude
  start1=71
  end1=74
  start2=118
  end2=122

  IF NOT keyword_set(varCol) THEN varCol=7 ; default to Latent Heat flux

  output=fltarr(2, n_elements(files))

  FOR i=0, n_elements(files)-1 DO BEGIN
     IF keyword_set(exclude) THEN BEGIN
        soil=(strsplit(files[i], '_', /extract))[2]
        IF strmatch(exclude[i], soil) THEN skip=1 $
        ELSE skip=0
     endIF
     IF NOT skip THEN BEGIN 
        junk=load_cols(files[i], data)
        subset1=data[varCol,start1:end1]
        subset2=data[varCol,start2:end2]

        output[*,i]= [mean(subset1), mean(subset2)]
     ENDIF ELSE output[*,i]=-9999
     
  ENDFOR
  output=output[*,where(output[0,*] NE -9999)]
  return, [mean(output[0,*]), $
           max(output[0,*])-min(output[0,*]), $
           stdev(output[0,*]), $
           mean(output[1,*]), $
           max(output[1,*])-min(output[1,*]), $
           stdev(output[1,*])]           
END


PRO plotSurfaces, data, locations, inputfile=inputfile
  IF keyword_set(inputfile) THEN BEGIN
     junk=load_cols(inputfile, data) 
     locations=data[0:1,*]
     data=data[2:7,*]
  ENDIF

  locations[0,*]/=100
  xt="initial Soil Moisture (%)"
  yt="Rainfall (mm)"
  zt=["Mean LE (W/m!U2!N)","Range  LE (W/m!U2!N)","Std.Dev. LE (W/m!U2!N)"]
  nx=26
  ny=26
  boxColor=1


  IF !d.name EQ 'X' THEN begin
     window, xs=1000,ys=1000
     boxColor=255
     !p.charsize=3
     con_char=1.5
  endIF


  !p.multi=[0,2,3]
  FOR i=0, 5 DO BEGIN 
     surface, reform(data[i,*], nx, ny), $
              reform(locations[0,*], nx,ny), $
              reform(locations[1,*], nx, ny), $
              ax=70, $
              xtit=xt,ytit=yt,ztit=zt[i MOD 3]
     contour, reform(data[i,*], nx, ny), $
              reform(locations[0,*], nx,ny), $
              reform(locations[1,*], nx, ny), $
              /irregular, nlevels=20, c_charsize=con_char, $
              c_label=[0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,1,1,1,1], $
              xtit=xt,ytit=yt,title=zt[i MOD 3]
     oplot, reform(locations[0,*], nx,ny), $
            reform(locations[1,*], nx, ny), $
            psym=3
     oplot, [0,20,20,0,0],[0,0,20,20,0], color=boxColor

  ENDFOR


end

PRO plot_varying, pattern=pattern, inputfile=inputfile, exclude=exclude

  IF keyword_set(inputfile) THEN BEGIN
     plotSurfaces, inputfile=inputfile
     return
  END

  IF NOT keyword_set(pattern) THEN pattern="output_*"
  files=file_search(pattern)

  data=fltarr(6,n_elements(files))
  locations=lonarr(2,n_elements(files))
  
  openw, oun, /get, "outputStatistics"
  WHILE (i LT n_elements(files)-1) DO BEGIN
     IF file_test(files[i], /directory) THEN BEGIN 
        cd, current=olddir, files[i]

        curStats=calcStats(file_search("out_*"), exclude=exclude)

        data[*,i]=curStats
        locations[*,i]=long((strsplit(files[i], '_', /extract))[1:2])

        printf, oun, locations[*,i], data[*,i]

        cd, olddir
     ENDIF
     IF i MOD 10 EQ 0 THEN print, float(i)/(n_elements(files)-1)*100, "%"
     i++
  ENDWHILE

  
  close, oun
  free_lun, oun

  plotSurfaces, data, locations
END

