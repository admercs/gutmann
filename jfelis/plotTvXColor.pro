FUNCTION getTitle, fname, index
  IF index GT 24 OR index LT 1 THEN return, "UNKNOWN"+strcompress(index)
  openr, un, /get, fname
  line=""
  curVal=-1
  curTitle=""

  WHILE NOT eof(un) AND (curVal NE index) DO BEGIN
     readf, un, line
     tmp=strsplit(line, /extract)
     curVal=fix(tmp[0])
     curTitle=tmp[2:*]
  ENDWHILE

  tmp=""
  FOR i=0,n_elements(curTitle)-1 DO $
     tmp+=curTitle[i]+' '

  close, un
  free_lun, un

  return, tmp
END


pro plotTvXColor, inputfile, plotfile, colorfile, day, curRes, subsetin, $
                  indexfile, ct=ct, ncover=ncover

  IF strmatch(subsetin, "*.tif") THEN $
    subset=(strsplit(subsetin, '.', /extract))[0] $
    ELSE subset=subsetin
  
  IF NOT keyword_set(ct) THEN ct=29

  data1=read_tiff(inputfile.ndvi)
  data2=read_tiff(inputfile.thermal)

  colordata=read_tiff(colorfile)

  index=where(data1 NE 1 AND data2 NE 1 AND data2 NE -9999 AND colordata NE 16)

  IF index[0] NE -1 THEN BEGIN
     data1=data1[index]
     data2=data2[index]
     colordata=colordata[index]
  ENDIF
;; convert NDVI from 0-20000 -> -1.0-1.0
  data1=(fix(data1)-10000)/10000.
;; convert thermal from DN to Kelvin
  data2=data2*0.02

  index=where(data1 GT -0.2 AND data2 GT 280 AND data2 LT 340)
  IF index[0] NE -1 THEN BEGIN
     data1=data1[index]
     data2=data2[index]
     colordata=colordata[index]
  ENDIF

  IF n_elements(index) LT 4 THEN return

  old=setuptvxplot(filename=plotfile)
  !p.multi=[0,1,2]

  plot, [0,1], [0,1], psym=3, $
    xr=[-0.2,1], yr=[280,340], /xs, /ys, $
    xtitle="NDVI", $
    ytitle="Surface Temperature (K)", $
    title=string("Day :"+strcompress(day)+ $
                 "     Pixel Size :"+strcompress(curRes)+ $
                 "km    "+strcompress(subset))


  loadct,ct
  colordex=lonarr(30)
  colordex[colordata]++

  colordata=(colordata*250/16) MOD 255
  plots, data1, data2, color=colordata, psym=3



  IF NOT keyword_set(ncover) THEN ncover=6.0
  ncover=float(ncover)
  step=1.0/(ncover*1.5)

  plot, [0,0], [2,3], xr=[0,1], yr=[0,1], xs=4, ys=4, $
        title=strcompress(fix(ncover), /remove_all)+ $
        " Most Commond Land Covers"
  npix=float(n_elements(colordata))
  FOR i=0,ncover-1 DO begin
     current=where(colordex EQ max(colordex))
     IF n_elements(current) GT 1 THEN current=current[0]
     IF current EQ -1 THEN current =16
     polyfill, [0,0.2,0.2,0], $
               [1-i/ncover,1-i/ncover,1-(step+i/ncover),1-(step+i/ncover)], $
               color=((current[0] *250/16)MOD 255)

     xyouts, 0.25, 1-(step +i/ncover)+step/10.0, $
             getTitle(indexfile, current)+ $
             ' ('+string(100*colordex[current]/npix, format='(F4.1)')+'%)'
     colordex[current]=0
  endFOR
  
  resetplot, old
end
