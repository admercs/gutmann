PRO getRangeStats, filename, minsoil=minsoil
  IF n_elements(filename) EQ 0 THEN filename="combinedOut"
  junk=load_cols(filename, data)
  nsoils=max(data[1,*])
  meds=fltarr(nsoils)
  aves=fltarr(nsoils)
  ranges=fltarr(nsoils)
  devs=fltarr(nsoils)

  fluxNames=["Ts", "H", "LE", "G"]
  IF NOT keyword_set(minsoil) THEN minsoil=0
  

  FOR col=12,12 DO BEGIN
     curSoil=0
     FOR i=minsoil,nsoils DO BEGIN
        dex=where(data[1,*] EQ i)
        IF dex[0] NE -1 THEN BEGIN
           meds[curSoil]=median(data[col,dex])
           aves[curSoil]=mean(data[col,dex])
           devs[curSoil]=stdev(data[col,dex])
           ranges[cursoil]=max(data[col,dex])-min(data[col,dex])
           curSoil++
        endIF
     ENDFOR

     total=0
     count=0
     FOR i=0,nsoils-1-minsoil DO BEGIN
        FOR j=0,nsoils-1-minsoil DO BEGIN
           total+=abs(meds[i]-meds[j])
           count++
        endFOR
     ENDFOR


     print, "----------------------------"
     print, fluxNames[col-10]
     print, "Range"
     print, mean(ranges[0:nsoils-1-minsoil])
;     print, max(ranges), min(ranges)
     print, "Sigma"
     print, mean(devs[0:nsoils-1-minsoil])
     print, "CV"
     print, mean(devs[0:nsoils-1-minsoil]/aves[0:nsoils-1-minsoil])
;     print, max(devs)-min(devs), max(devs), min(devs)
     print, "Medians"
     print, max(meds[0:nsoils-1-minsoil])-min(meds[0:nsoils-1-minsoil])
     print, total/count
     print, stdev(meds[0:nsoils-1-minsoil])
     print, stdev(meds[0:nsoils-1-minsoil])/mean(meds[0:nsoils-1-minsoil])
     print, ""
  endFOR

END

