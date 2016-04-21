PRO spatialMet, datafile, infofile, prefix=prefix;, defaultFile
;  IF n_elements(defaultfile) EQ 0 THEN defaultfile="IHOPUDS1"
  IF n_elements(infofile) EQ 0 THEN infofile="metinfo.txt"
  IF n_elements(datafile) EQ 0 THEN datafile="metdata.txt"
  IF NOT keyword_set(prefix) THEN prefix=''
;  mapBounds=[33.7,-107.4, 34.6,-106.3]
;  mapResolution=[0.02,0.02]
  mapbounds=[double(304464.0), double(3777626.0), double(361664.0), double(3818726.0)]
  mapResolution=[1000,1000]
  b=mapbounds
  bx2=mean(mapbounds[[0,2]])
  by2=mean(mapbounds[[1,3]])

  j=load_cols(datafile, data)
  j=load_cols(infofile, info)
;  j=load_cols(defaultfile, default)

  data[0,*]+=100
  nStations=n_elements(info[0,*])
  FOR i=0l,nStations-1 DO BEGIN
     curdex=where(data[0,*] EQ (info[0,i]+100))
     IF curdex[0] NE -1 THEN data[0,curdex] = i
     info[0,i]=i
  endFOR


  variableCols=[4,7,8,16,17,20,25]
  
  time=ulong64(data[1,*])*ulong64(100000) +ulong64(data[2,*]*100)+ulong64(data[3,*])
  dex=sort(time)

  x=fltarr(2*nStations)
  y=x
  z=x

;; loop through all variables krigging and writing data to an output file
  FOR var=0,n_elements(variableCols)-1 DO BEGIN 
     print, "Working on variable"+strcompress(variableCols[var])
     
     openw, oun, /get, prefix+'spatialMet'+strcompress(variableCols[var], /remove_all)

     i=ulong64(0)
     WHILE i LT n_elements(dex)-1 DO BEGIN
        curtime=time[dex[i]]
        itime=curtime
        curStations=0
        WHILE iTime EQ curtime AND i LT n_elements(dex)-1 DO BEGIN 
           
;           iTime=time[dex[i]]
           value=data[variableCols[var],dex[i]]
           station=data[0,dex[i]]
           IF value NE -999 AND value NE -888 AND value NE 6999 THEN BEGIN 
              x[curStations]=info[2,station]
              y[curStations]=info[1,station]
              z[curStations]=value

              curStations++
           endIF
           i++
           IF i LT n_elements(dex)-1 THEN itime=time[dex[i]]
        ENDWHILE 

        zval=mean(z[0:curstations-1])
        zvals=[z[0:curstations-1],zval,zval,zval,zval,zval,zval,zval,zval]
        xvals=[x[0:curstations-1],b[0],b[0],b[0],bx2,b[2],b[2],b[2],bx2]
        yvals=[y[0:curstations-1],b[1],by2,b[3],b[3],b[3],by2,b[1],b[1]]
 
       curmap=min_curve_surf(zvals,xvals,yvals, $
                      bounds=mapBounds, gs=mapResolution);, exponential=[100000,0])
;        stop
        writeu, oun, curmap
        
     ENDWHILE
     help, curmap
     close, oun
     free_lun, oun
  endFOR
END

     
