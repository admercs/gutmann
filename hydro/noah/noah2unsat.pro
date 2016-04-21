;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; VERIFIED ON TEST FILE, NOT ROBUST TO FILE FORMAT CHANGES, NO ERROR CHECKING
;;
;; READS in the noah_offline.namelist file
;;
FUNCTION readbasic, fname

  line=''
  SKIP_SIZE=3 ;; lines to skip after reading in the start day

  headersize=6                  ; this will skip over the spatial dimensions because
                                ; we assume they are both 1, it will also skip over
                                ; the directory containing all the other files because
                                ; we assume they are in the same directory for now...

  openr, un, /get, fname

;; skip over the header and other unimportant info
  FOR i=1, headersize DO readf, un, line

;; read the number of soil layers
  readf, un, line
  NSOIL= fix((strsplit(line, '=',/extract))[1])

;; read in the depths of each soil layer
  depths=fltarr(NSOIL)
  FOR i=0,NSOIL-1 DO BEGIN
     readf, un, line
     depths[i]=float((strsplit(line, '=',/extract))[1])
  ENDFOR

  readf, un, line ;skip blank line


  readf, un, line ;; read in the starting year
  YEAR  = fix((strsplit(line, '=',/extract))[1])  

  readf, un, line ;; read in the starting month
  MONTH = fix((strsplit(line, '=',/extract))[1])

  readf, un, line ;; read in the starting day
  DAY   = fix((strsplit(line, '=',/extract))[1])

  ;; skip over lines we don't care about
  FOR i=1, SKIP_SIZE DO readf, un, line


  readf, un, line ;; read in the number of days in the simulation
  NDAYS = fix((strsplit(line, '=',/extract))[1])
  readf, un, line ;; skip blank line

  readf, un, line ;; read in the time step delta t
  dt    = float((strsplit(line, '=',/extract))[1])

  readf, un, line ;; read in the bottom constant temperature
  T_bot = float((strsplit(line, '=',/extract))[1])
  
  close, un
  free_lun, un

  return, {NSOIL:NSOIL, depths:depths, yr:YEAR, mo:MONTH, day:DAY, $
           ndays:NDAYS, dt:dt, T_bot:T_bot}
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VERIFIED
;; for now only works with ONE location at a time 
;; reads the index into the SOILPARM.TBL file row number
FUNCTION readType, file
  line=''
  type=0
  openr, un, /get, file
;; skip header
  readf, un, line
  readf, un, line
;; read the soil type index
  readf, un, type

  close, un
  free_lun, un
  return, type
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VERIFIED
;; read in SOILPARM.TBl
;; returns an float array with the soiltype names chopped off
FUNCTION readData, file
  line=''
  HEADER=3
  openr, un, /get, file
  
  FOR i=1, HEADER DO readf, un, line
  soilList=fltarr(11)

  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     dat=strsplit(line, ',', /extract)
     dat=dat[0:n_elements(dat)-2]
     soilList=[[soilList],[float(dat)]]
  ENDWHILE
  soilList=soilList[*, 1:n_elements(soilList[0,*])-1]
  
  close, un
  free_lun, un
  return, soilList
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VERIFIED
;; returns an array of the soil parameters to be used
FUNCTION readSoildata, soiltypefile, soildatafile

  soildex = readType(soiltypefile)
  soildat = readData(soildatafile)
  
  return, soildat[*, soildex-1]
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VERIFIED
;; Trivial function with load_cols, most of the work will be done in
;;   translating this information for UNSAT.
FUNCTION readForcingData, filename
  j=load_cols(filename, dat)
  return, dat
END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VERIFIED
;; read in the initial Soil Moisture Content (SMC) and
;;   the initial soil Temperature (temp)
FUNCTION readInit, initFile
  j=load_cols(initfile, dat)
  sz=n_elements(dat)
  IF sz MOD 2 NE 0 THEN print, 'ERROR in the initialization'
  SMC=dat[0:(sz/2)-1]
  temp=dat[sz/2:sz-1]

  return, {SMC:SMC, temp:temp}
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VERIFIED
;; read NOAH_IHOP input files and parse them into a structure
FUNCTION read_NOAH_IHOP_files, directory
  cd, directory, current=old
  
;; for now these names are hard coded because they are hard coded into NOAH (IHOP)

;; read layer info, ndays, starting day-time-year, dt, bottom Temperature
  basic = readBasic('noah_offline.namelist')

;; read soil hydraulic properties, ignore thermal for now
  soils = readSoildata('IHOPstyp', 'SOILPARM.TBL')
 
; we aren't currently using veg data in UNSAT 
;  veg   = readVegData, 'IHOPluse', 'VEGPARM.TBL'

;; read weather forcing data, precip, temp, windspeed, solar radiation
  force = readForcingData('IHOPUDS1')

;; read in the initial soil state
  init  = readinit('IHOPsoil')

  return, {basic:basic, soil:soils, forcing:force, init:init}
END



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; conversion utilities
;;   The following routines are used to convert units
;;   and time averaging periods from those used by
;;   NOAH to those used by UNSAT
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VERIFIED
FUNCTION convertInit, init
  SMCfactor=100 ;(meters?? to cm)

  smc=init.smc*SMCfactor
  temp=init.temp+273.15

  return, {smc:smc, temp:temp}
END

FUNCTION julianFromNum, day, mon, yr
  if n_elements(yr) eq 0 then yr=1
  if mon  gt 12 then begin
    print, 'You entered : ', mon, ' : for the month'
    return, 0
  endif

  case mon of
     1 : base=0
     2 : base=31
     3 : base=59
     4 : base=90
     5 : base=120
     6 : base=151
     7 : base=181
     8 : base=212
     9 : base=243
     10 : base=273
     11 : base=304
     12 : base=334
     else  : begin
        print, 'You entered : ', mon, ' for the month.'
        return, 0
     endelse
  endcase
  if ((yr mod 4) eq 0) and (mon le 2) then base=base+1
  
  return, base+day
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VERIFIED
FUNCTION convertBasic, basic
  firstDay=julianFromNum(basic.day, basic.mo, basic.yr) ;... or somesuch
  lastDay =firstDay+basic.ndays-1
  depths=basic.depths*(-100) ;m->cm
  return, {firstDay:firstDay, lastDay:lastDay, T_bot:basic.T_bot, $
           ndays:basic.ndays-1, nsoil:basic.nsoil, depths:depths}
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VERIFIED
FUNCTION convertSoil, soil
  return, {b:soil[1], airent:(soil[6]/0.07), Ks:(soil[7]*60*60*100), $
           theta_r:soil[2], theta_s:soil[4]}
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; FORCEING CONVERSIONS
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VERIFIED
FUNCTION convertWinds, force, day
  first=day*48l-1
  last=first+47
  IF first LT 0 THEN first=0

  return, mean(force[5,first:last]) *2.37 ;m/s -> mi/hr
END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VERIFIED
FUNCTION convertTmax, force, day
  first=day*48l-1
  last=first+47
  IF first LT 0 THEN first=0

  return, (max(force[6,first:last])  *(9./5)) +32 ;C -> F
END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VERIFIED
FUNCTION convertTmin, force, day
  first=day*48l-1
  last=first+47
  IF first LT 0 THEN first=0

  return, (min(force[6,first:last])  *(9./5)) +32 ;C -> F
END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VERIFIED
FUNCTION convertSolar, force, day
  first=day*48l-1
  last=first+47
  IF first LT 0 THEN first=0

  return, mean(force[8,first:last])*24/11.63333 ;W/m^2 (/hr??) ->Langleys (/d??) 
;; this conversion makes very little sense as a W (and a ly) is already a rate.  
END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VERIFIED
FUNCTION convertRain, force, day
  first=day*48l-1
  last=first+47
  IF first LT 0 THEN first=0

  return, (total(force[10,first:last])/20)/2.52 ;mm/hr->cm->in
END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VERIFIED
FUNCTION readRain, force, day
  first=(day-1)*48l-1
  last=first+47
  IF first LT 0 THEN first=0
  hours=transpose(indgen(48)/2.)

  rain=[hours, force[10,first:last]/20]
  rain=[[day, 48],[rain]]

  return, rain
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VERIFIED
;; or would this be better done by day...
FUNCTION  convertForcing, force, ndays
  rain=fltarr(2,49)
  weather=fltarr(7,ndays)
;  tmax=0  & tmin=1 & dewpt=2 & solar=3 & wind=4 & cloud=5 & prec=6
  tmax=0  & tmin=1 & dewpt=2 & solar=3 & wind=4 & cloud=5 & prec=6
  nwater=0
  FOR i=0,ndays-1 DO BEGIN
     weather[wind,i]=convertWinds(force,i)
     weather[tmax,i]=convertTmax(force,i)
     weather[tmin,i]=convertTmin(force,i)
     weather[solar,i]=convertSolar(force,i)
     weather[prec,i]=convertRain(force,i)

; hack because NOAH doesn't provide RH or dewpoint
     weather[dewpt,i]=weather[tmin,i]-10 
     IF weather[prec,i] NE 0 THEN BEGIN
        nwater=nwater+1
        rain=[[[rain]],[[readRain(force,i+1)]]]
     ENDIF
  ENDFOR
  rain=rain[*,*,1:n_elements(rain[0,0,*])-1]

  return, {weather:weather, nwater:nwater, rain:rain}
END



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VERIFIED
FUNCTION convertInfo, info
  
  unsatInit = convertInit(info.init)
  unsatBasic= convertBasic(info.basic)
  unsatSoil = convertSoil(info.soil)
  unsatForce= convertForcing(info.forcing, unsatBasic.ndays)

  return, {basic:unsatBasic, init:unsatInit, soil:unsatSoil, forcing:unsatForce}

END

;; sorry this is long, but it makes the most sense
PRO writeUNSATfile, fname, info, firstDay=firstDay, lastDay=lastDay
  if not keyword_set(firstDay) then firstDay=info.basic.firstDay
  if not keyword_set(lastDay) then lastDay=info.basic.lastDay


  openw, oun, /get, fname

  printf, oun, 'Simulation derived from NOAH model'
  printf, oun, '0, 1,                           IPLANT, NGRAV'
  printf, oun, lastDay,', ',firstday,', ',lastday
  printf, oun, '1,1,0,0,0                       IYS, NYEARS, ISTEAD, IFLIST, NFLIST'
  printf, oun, '1,24.0,                         NPRINT,STOPHR'
  printf, oun, '1,20,1,1.0E-2,                  ISMETH,INMAX,ISWDIF,DMAXBA'
  printf, oun, '0.025,1.0E-25,1.0,              DELMAX,DELMIN,OUTTIM'
  printf, oun, '2.0,1.0E-05,0.0,0.0,0.0,        RFACT,RAINIF,DHTOL,DHMAX,DHFACT'
  printf, oun, '3,3,0.0,                        KOPT,KEST,WTF'
  printf, oun, '0,1,2,1,                        ITOPBC,IEVOPT,NFHOUR,LOWER'
  printf, oun, '0.0,1.0E+10,20.0,0.10,          HIRRI,HDRY,HTOP,RHA'
  printf, oun, '1,0,1,                          IETOPT,ICLOUD,ISHOPT'
  printf, oun, '0,0.2,                          IRAIN,HPR'
  printf, oun, '0,0.0,0.0,0.0,NoFile,           IHYS,AIRTOL,HYSTOL,HYSMXH,HYFILE'
  printf, oun, '1,1,0.0,                        IHEAT,ICONVH,DMAXHE'
  printf, oun, '0,0.0,0.0,0.0,                  UPPERH,TSMEAN,TSAMP,QHCTOP'
  printf, oun, '1,0.0,0.00001,                  LOWERH,QHLEAK,TGRAD'
  printf, oun, '1,0.66,288.46,0.24,             IVAPOR,TORT,TSOIL,VAPDIF'
  printf, oun, '1,',strcompress(info.basic.nsoil)+1,',                           MATN,NPT'
  printf, oun, '1,  0.000, 1,', strcompress(info.basic.depths[0]), ', ', $
          '1,', strcompress(info.basic.depths[1]), ', ', $
          '1,', strcompress(info.basic.depths[2]), ','
  FOR i=6, info.basic.nsoil-1, 4 DO BEGIN
     printf, oun, '1,', strcompress(info.basic.depths[i-3]), ', ', $
             '1,', strcompress(info.basic.depths[i-2]), ', ', $
             '1,', strcompress(info.basic.depths[i-1]), ', ', $
             '1,', strcompress(info.basic.depths[i]), ','
  ENDFOR
  tmp=''
  i=i-3
  WHILE i LT info.basic.nsoil DO BEGIN
     tmp=tmp+'1, '+strcompress(info.basic.depths[i])+', '
     i=i+1
  ENDWHILE
  printf, oun, tmp
  printf, oun, 'Brooks-Corey Suc-Sat Parameters,'
  printf, oun, strcompress(info.soil.theta_s),', ',strcompress(info.soil.theta_r), $
          ', ',strcompress(info.soil.airent),', ',strcompress(info.soil.b),','
  printf, oun, 'Mualem values,'
  printf, oun, '2, ',strcompress(info.soil.Ks),', ',strcompress(info.soil.airent), $
          ', ',strcompress(info.soil.b),', 0.5,'
  printf, oun, 'Mat. #2, Silt Loam Thermal Conductivity Parameters UNCHANGED'
  printf, oun, '0.6,0.8,4.5,0.22,6.0,2.39,        TCON(A,B,C,D,E),CHS'
  printf, oun, 'Mat. #2, Silt Loam Enhancement Factor Parameters UNCHANGED'
  printf, oun, '1.0,0.0,0.0,1.0,4.0,              EF(A,B,C,D,E)'
  printf, oun, strcompress(info.basic.firstday), ', Day for init values'
  printf, oun, strcompress(info.init.smc[0]),', ', $
          strcompress(info.init.smc[0]), ', ',$
          strcompress(info.init.smc[1]), ', ',$
          strcompress(info.init.smc[2]), ','
  FOR i=6, info.basic.nsoil-1, 4 DO BEGIN
     printf, oun, strcompress(info.init.smc[i-3]), ', ', $
             strcompress(info.init.smc[i-2]), ', ', $
             strcompress(info.init.smc[i-1]), ', ', $
             strcompress(info.init.smc[i]), ','
  ENDFOR
  tmp=''
  i=i-3
  WHILE i LT info.basic.nsoil DO BEGIN
     tmp=tmp+strcompress(info.init.smc[i])+', '
     i=i+1
  ENDWHILE
  printf, oun, tmp
 
  printf, oun, strcompress(info.init.temp[0]),', ', $
          strcompress(info.init.temp[0]), ', ',$
          strcompress(info.init.temp[1]), ', ',$
          strcompress(info.init.temp[2]), ','
  FOR i=6, info.basic.nsoil-1, 4 DO BEGIN
     printf, oun, strcompress(info.init.temp[i-3]), ', ', $
             strcompress(info.init.temp[i-2]), ', ', $
             strcompress(info.init.temp[i-1]), ', ', $
             strcompress(info.init.temp[i]), ','
  ENDFOR
  tmp=''
  i=i-3
  WHILE i LT info.basic.nsoil DO BEGIN
     tmp=tmp+strcompress(info.init.temp[i])+', '
     i=i+1
  ENDWHILE
  printf, oun, tmp
  printf, oun, '0.0001,0.0001,5.0,10.0,0.0,34.34, ZH,ZM,ZT,ZU,D,LAT'
  ;; Meteorologic data
;  FOR i=0, info.basic.ndays-1 DO BEGIN
  rainday=0
  FOR i=firstDay, lastDay DO BEGIN
     tmp=strcompress(i+1)+', '
     FOR j=0, 6 DO $
       tmp=tmp+strcompress(info.forcing.weather[j,i])+', '
     printf, oun, tmp
     if info.forcing.weather[j-1,i] gt 0 then $
       rainday=rainday+1
  ENDFOR 

;; Rainfall data
;  printf, oun, info.forcing.nwater,','
  printf, oun, rainday,','
  rain=info.forcing.rain
  bad=0
  FOR i=0, info.forcing.nwater-1 DO BEGIN
     tmp=''
     IF rain[0,0,i] LE lastDay AND rain[0,0,i] GE firstDay THEN BEGIN  
 ;    if rain[1,0,i] gt 0 then begin
 ;       printf, oun, fix(rain[0,0,i]), ', 1, 25, 1.0,'
 ;       printf, oun, rain[0,j,i], ', ', rain[1,j,i],','
 ;    endif else      printf, oun, fix(rain[0,0,i]), ', 1, 24, 1.0,'
      printf, oun, fix(rain[0,0,i]), ', 1, 24, 1.0,'

     FOR j=1,48,2 DO BEGIN
        printf, oun, rain[0,j+1,i], ', ', rain[1,j,i]+rain[1,j+1,i],','
     ENDFOR 
     ENDIF ELSE bad=bad+1
  ENDFOR 
  close, oun  &  free_lun, oun
  print, info.forcing.nwater-bad
END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
;; main program
;;
;; Read IHOP data, convert it to UNSAT format, write it to UNSAT file
PRO noah2unsat, noahdir, unsatfile, lastday=lastday, firstday=firstday

  IHOP_info=read_NOAH_IHOP_files(noahdir)
  
  UNSAT_info=convertInfo(IHOP_info)
  
  writeUNSATfile, unsatfile, UNSAT_info, lastday=lastday, firstday=firstday

END

