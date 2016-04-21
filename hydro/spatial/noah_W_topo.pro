PRO computeSolarAngles, time, lat, lon, angles
  hours=fix(time[3,*]/10000)
  minutes=(time[3,*]/100) MOD 100
  daytime=hours+minutes/60.0

  day_OF_Month=time[2,*]
  month = time[1,*]
  year=time[0,*]
  day=intarr(n_elements(year))

  FOR i=0l,n_elements(month)-1 DO $
    day[i]=getDOY(day_OF_Month[i], month[i], year[i])

  zensun, day+fix((daytime+7)/24), (daytime+7) MOD 24, lat, lon, zenith, azimuth

  azimuth+=180
;  print, daytime[0], zenith[0], azimuth[0]

  angles=[[zenith], [azimuth]]
END


PRO computeCosTheta, topo, solar,cosTheta, base=base

  IF NOT keyword_set(base) THEN base=1
  topoangle=double(rebin(zenaz_2_vec(double(topo[0]),double(topo[1])),3,n_elements(solar[*,0])))
  solarangle=dblarr(3,n_elements(solar[*,0]))
  FOR i=0l, n_elements(solar[*,0])-1 DO $
    solarangle[*,i]=zenaz_2_vec(double(solar[i,0]), double(solar[i,1]))
  
  cosTheta=total(topoangle*solarangle,1) $  ; dot product
           / (sqrt(total(topoangle^2,1))*sqrt(total(solarangle^2,1)))  ; magnitude

;; apply a few corrections for cases where the sun is hidden

  index=where(solarangle[2,*] LE 0)
  IF index[0] NE -1 THEN $
    cosTheta[index] = 0         ; the sun is below the horizon
                                ; (note that cos theta may still be positive)


  index=where(cosTheta LT 0)
  IF index[0] NE -1 THEN $
    cosTheta[index] = 0 ; the sun is more than 90 degrees from the surface

  index=where(base GT 0 AND base NE 1)
  IF index[0] NE -1 THEN $
    cosTheta[index]=cosTheta[index]/base[index] <4              ; lets us normalize to a flat surface cosine angle

END

PRO writeWeather, weather, cosTheta, noahdir, bg=bg, $
                  temperature=temperature, pressure=pressure, precip=precip, $
                  wind=wind, humidity=humidity, radiation=radiation

  newweather=weather
  newweather[8,*]*=cosTheta
  ;5=wind, 6=temperatures, 8=radiation, 10=rain
  newend=min([max([n_elements(humidity), n_elements(temperature), n_elements(precip), $
                   n_elements(wind), n_elements(radiation), n_elements(pressure) $
                  ]), n_elements(weather[0,*])])
  newend--
  IF keyword_set(temperature) THEN newweather[6,0:newend]=temperature[0:newend]
  IF keyword_set(wind) THEN newweather[6,0:newend]=wind[0:newend]
  IF keyword_set(radiation) THEN newweather[6,0:newend]=radiation[0:newend]
  IF keyword_set(precip) THEN newweather[6,0:newend]=precip[0:newend]

  cd, current=oldDir
  openw, oun, /get, "IHOPUDS"+strcompress(1+bg, /remove_all)
  printf, oun, "Date"
  printf, oun, "GMT                             1       1       1       1       1       1       1       1       1       1"
  printf, oun, "YEAR    month   newday  newtime P       windspd T       MR      Rsw.in  Rlw.in  rainr   LAI     NDVI    Fg"
  printf, oun, "yyyy    mm                      mb-true m/s     (degC)  (g/kg)  (W/m^2) (W/m^2) (mm/hr)"
  
  printf, oun, newweather, format='(3I5,I8,7F10.3,I3,2F6.3)'

  close, oun
  free_lun, oun
END

PRO saveresults, noahdir,i,j, bg=bg
  cd, current=old
  cd, noahdir
  IF keyword_set(bg) THEN outputfile="noahOutput" ELSE outputfile="noahOutput1"
  spawn, "mv "+outputfile+" "+strcompress(i,/remove_all)+ $
         "_"+strcompress(j,/remove_all)+".out"
  cd, old
END

PRO runNoah, noahdir, background=background
  cd, current=oldDir
  cd, noahdir
;; it turns out that IDL will spend more time setting up the next run so we might
;; always background noah... but for now play it safe
  IF keyword_set(background) THEN spawn, "./noah1 >/dev/null &" ELSE spawn, "./noah2 >/dev/null "
  cd, oldDir
END

PRO load_topo, topofile, resultInfo

  topography=read_tiff(topofile, geotiff=geoinfo)
  
  resolution=geoinfo.MODELPIXELSCALETAG
  tiepoint=geoinfo.MODELTIEPOINTTAG
  proj=geoinfo.PROJECTEDCSTYPEGEOKEY 
; see http://www.remotesensing.org/geotiff/spec/geotiff6.html#6.3.3.1
;  for what this key means

  sz=size(topography)
  center=[(sz[2]/2.0-tiepoint[0]) *resolution[0] + tiepoint[3], $
          (sz[3]/2.0-tiepoint[1]) *resolution[1] + tiepoint[4]]
  zone=proj MOD 100
  CASE fix(proj / 100) OF 
     267 : datum="NAD27" ;north
     269 : datum="NAD83" ;north
     322 : datum="WGS72" ;north
     323 : datum="WGS72" ;south
     324 : datum="WGS72BE" ;north
     325 : datum="WGS72BE" ;south
     326 : datum="WGS84" ;north
     327 : datum="WGS84" ;south
  END
     

  ll=utm_to_ll(center[0], center[1], datum, zone=zone)
  
  resultInfo={topo:transpose(topography, [1,2,0]), lat:ll[1], lon:ll[0]}
END

FUNCTION getGeneric, File, sz, resolution, curX, curY, data=data


  IF NOT keyword_set(data) THEN BEGIN 
     openr, un, /get, File
     data=dblarr(sz[0], sz[1], sz[2])
     readu, un, data
     close, un
     free_lun, un
  ENDIF

  resolution=float(resolution)

  x=curX/resolution[0]
  y=curY/resolution[1]

  IF floor(x) EQ ceil(x) AND floor(y) EQ ceil(y) THEN BEGIN 
     tmp=data[x, y, *]

     return, tmp
  endIF ELSE IF floor(x) EQ ceil(x) THEN BEGIN 
     tmp=data[x,floor(y):ceil(y),*]
     newSpatial=rebin(tmp, 1, resolution[1]*2, sz[2])
     ymod=fix((y MOD 1)*resolution[1])

     return, newSpatial[0, ymod, *]
  ENDIF ELSE IF floor(y) EQ ceil(y) THEN BEGIN 
     tmp=data[floor(x):ceil(x),y,*]
     newSpatial=rebin(tmp, resolution[0]*2, 1, sz[2])
     xmod=fix((x MOD 1)*resolution[0])

     return, newSpatial[xmod, 0, *]

  ENDIF ELSE tmp=data[floor(x):ceil(x),floor(y):ceil(y),*]

  
  ;; we have a two by two set of points we need to interpolate and find
  ;; the correct value a fraction of a way between the four points

  ;; interpolate to a grid that is twice the size we are looking for because
  ;;  rebin sets the right hand point to the left side of the right box (e.g. the middle)
  newSpatial=rebin(tmp, resolution[0]*2, resolution[1]*2, n_elements(tmp[0,0,*]))

  ;; find how far we need to go into the interpolated space
  xmod=fix((x MOD 1)*resolution[0])
  ymod=fix((y MOD 1)*resolution[1])

  return, newSpatial[xmod, ymod, *]
END

FUNCTION calcMR, humidity, temp, pressure, vaporP=vaporP
  mathe=2.718281828
  L = 2.5*10.0^6 ; [=] J/kg
  Rv = 461       ; [=] J/(K*kg)
  saturatedVaporP=611 * mathe^(L/Rv*(1.0/273.0-1.0/temp))
  return, humidity
END

FUNCTION getTemp, temperatureFile, sz, resolution, curX, curY, data=data
  ndata=getGeneric(temperatureFile, sz, resolution, curX, curY, data=data)

  return, (rebin(reform(ndata),sz[2]*resolution[2]) >(-30))<70
END

FUNCTION getPres, pressureFile, sz, resolution, curX, curY, data=data
  ndata=getGeneric(pressureFile, sz, resolution, curX, curY, data=data)

  return, (rebin(reform(ndata),sz[2]*resolution[2]) >600)<1200
END
FUNCTION getRain, precipFile, sz, resolution, curX, curY, data=data
  ndata=getGeneric(precipFile, sz, resolution, curX, curY, data=data)

  return, (rebin(reform(ndata/resolution[2]),sz[2]*resolution[2], /sample) >0)<100
END
FUNCTION getWind, windFile, sz, resolution, curX, curY, data=data
  ndata=getGeneric(windFile, sz, resolution, curX, curY, data=data)

  return, (rebin(reform(ndata),sz[2]*resolution[2]) >0) <100
END
FUNCTION getMixingRatio, RHumidityFile, temperatureFile, pressureFile, vaporP=vaporP, $
  sz, resolution, curX, curY, data=data
; this is a bit harder
  ndata=getGeneric(RHumidityFile, sz, resolution, curX, curY, data=data)
  temp=getGeneric(temperatureFile, sz, resolution, curX, curY)
  press=getGeneric(pressureFile, sz, resolution, curX, curY)

  MR=calcMR(ndata, temp, press, vaporP=vaporP)

  return, (rebin(reform(MR),sz[2]*resolution[2])>0)<100 
END
FUNCTION getSun, radiationFile, sz, resolution, curX, curY, data=data
  ndata=getGeneric(radiationFile, sz, resolution, curX, curY, data=data)
  ndata*=2.7778

  return, rebin(reform(ndata),sz[2]*resolution[2]) 
END

PRO noah_W_topo, topofile, weatherfile, noahdir, fillgaps=fillgaps, $
                 temperature=temperature, pressure=pressure, precip=precip, vapor=vapor, $
                 wind=wind, humidity=humidity, radiation=radiation, ws=ws, res=res

  IF (keyword_set(temperature) OR keyword_set(pressure) OR keyword_set(precip) $
      OR keyword_set(vapor) OR keyword_set(wind) OR keyword_set(humidity) $
      OR keyword_set(radiation))  AND NOT (keyword_set(res) AND keyword_set(ws)) THEN BEGIN 
     print, 'ERROR : if you wish to use spatially distributed weather than '
     print, '   You must specify both the weather size (ws keyword) and the '
     print, '   resolution of this data with respect to the topography file (res keyword)'
     print, '     if topo resolution=100m and weather resolution=1km '
     print, '     and weather time resolution = 1hr, model time res= 1/2 hr then'
     print, '     res = [10,10,2]'
     return
  ENDIF

  IF keyword_set(humidity) AND $
    NOT ((keyword_set(pressure) OR keyword_set(vapor)) AND keyword_set(temperature) $
         OR keyword_set(fromWeatherfile)) THEN BEGIN 
     print, 'ERROR : if you wish to calculate mixing ratio from humidity'
     print, '   You must specify either pressure or vapor pressure, and '
     print, '   You must specify temperature'
     print, '   alternatively you can set the fromWeatherfile keyword to take these parameters'
     print, '   from the default weatherfile'
     return
  endIF

  IF keyword_set(temperature) THEN BEGIN 
     openr, un, /get, temperature
     tempData=dblarr(ws[0], ws[1],ws[2])
     readu, un, tempData
     close, un
     free_lun, un
     tempData=float(tempData)
  ENDIF 
  IF keyword_set(pressure) THEN BEGIN 
     openr, un, /get, pressure
     pressureData=dblarr(ws[0], ws[1],ws[2])
     readu, un, pressureData
     close, un
     free_lun, un
     pressureData=float(pressureData)
  ENDIF 
  IF keyword_set(precip) THEN BEGIN
     openr, un, /get, precip
     precipData=dblarr(ws[0], ws[1],ws[2])
     readu, un, precipData
     close, un
     free_lun, un
     precipData=float(precipData)
  ENDIF 
  IF keyword_set(wind) THEN BEGIN 
     openr, un, /get, wind
     windData=dblarr(ws[0], ws[1],ws[2])
     readu, un, windData
     close, un
     free_lun, un
     windData=float(windData)
  ENDIF 
  IF keyword_set(radiation) THEN BEGIN 
     openr, un, /get, radiation
     radiationData=dblarr(ws[0], ws[1],ws[2])
     readu, un, radiationData
     close, un
     free_lun, un
     radiationData=float(radiationData)
  ENDIF 
  IF keyword_set(humidity) THEN BEGIN 
     openr, un, /get, humidity
     humidityData=dblarr(ws[0], ws[1],ws[2])
     readu, un, humidityData
     close, un
     free_lun, un
     humidityData=float(humidityData)
  ENDIF 
     
  

  junk=load_cols(weatherfile, weather)
  load_topo, topofile, geoInfo

  topography=geoInfo.topo
  lat=geoInfo.lat
  lon=geoInfo.lon

  computeSolarAngles, weather[0:3,*], lat, lon, solarVec

  computeCosTheta, [0,100],solarVec, baseCosine

;  current=ulong64(0)
  save=0
  FOR i=0l, n_elements(topography[*,0,0])-1 DO BEGIN
     FOR j=0l,n_elements(topography[0,*,0])-1 DO BEGIN 
        IF NOT keyword_set(fillgaps) OR $
          NOT file_test(noahdir+"/"+strcompress(i,/remove_all)+ $
                         "_"+strcompress(j,/remove_all)+".out") THEN BEGIN 
;           bg=(j+1) MOD 2
           bg=0
           computeCosTheta, topography [i,j,*], solarVec, cosTheta, base=baseCosine

           IF keyword_set(temperature) THEN temp=getTemp(temperature, ws, res, i,j, data=tempData)
           IF keyword_set(pressure) THEN    pres=getPres(pressure, ws, res, i,j, data=pressureData)
           IF keyword_set(precip) THEN      rain=getRain(precip, ws, res, i,j, data=precipData)
           IF keyword_set(wind) THEN        airspeed=getWind(wind, ws, res, i,j, data=windData)
           IF keyword_set(radiation) THEN   rad=getSun(radiation, ws, res, i,j, data=radiationData)
           IF keyword_set(humidity) THEN    BEGIN 
              IF keyword_set(pressure) THEN $
                MR=getMixingRatio(humidity, temperature, pressure, ws, res, i,j) $
                ELSE IF keyword_set(vapor) THEN $
                MR=getMixingRatio(humidity, temperature, vapor, ws, res, i,j, /vaporP) $
                ELSE IF keyword_set(fromWeatherfile) THEN $
                MR=getMixingRatio(humidity, weather, ws, res, i,j, /weather) $
                ELSE print, "ERROR no pressure specified!"
           ENDIF
           writeWeather, weather, cosTheta, noahdir, bg=bg, $
                         temperature=temp, pressure=pres, precip=rain, $
                         wind=airspeed, humidity=MR, radiation=rad

           ;; save results here rather than after to give the last noah
           ;; process as long as possible to complete?  
;           IF save NE 0 THEN saveresults, noahdir, lasti,lastj, bg= ~bg ELSE save=1
;           lasti=i
;           lastj=j
;           current++
           runNoah, noahdir, background=bg
           saveresults, noahdir, i, j, bg=bg
        ENDIF
     ENDFOR
     IF i MOD 10 EQ 0 THEN print, float(i)/n_elements(topography[*,0,0]) * 100
  ENDFOR
  saveresults, noahdir, lasti,lastj, bg=~bg
END
