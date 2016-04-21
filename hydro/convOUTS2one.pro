FUNCTION textIndex, texture
  CASE strcompress(strlowcase(texture), /remove_all) OF 
     "sand" :            index=0
     "loamysand" :      index=1
     "sandyloam" :      index=2
     "siltloam" :       index=3
     "silt" :            index=4
     "loam" :            index=5
     "sandyclayloam" : index=6
     "siltyclayloam" : index=7
     "clayloam" :       index=8
     "sandyclay" :      index=9
     "siltyclay" :      index=10
     "clay" :            index=11
  ENDCASE
  return, index
END

;; return dt (model output time step) in minutes
FUNCTION finddt, times
  timechange=times[1]-times[0]

  IF timechange LT 60 THEN return, timechange ;; this is almost always what will happen

;; unless we happend to flip an hour
  IF timechange LT 2400 THEN BEGIN 
     hours=ulong64(times[0:1]/100)
     minutes=fix(times[0:1] MOD 100)
     return, (hours[1] - hours[0])*60.0 + minutes[1] - minutes[0]
  ENDIF 
  
;; if timechange is greater than 2400 than we must have flipped a day, look at the next time step
;; to see if it is any better
  timechange=times[2]-times[1]
  
  IF timechange LT 60 THEN return, timechange ;; this is almost always what will happen

  IF timechange LT 2400 THEN BEGIN 
     hours=ulong64(times[0:1]/100)
     minutes=fix(times[0:1] MOD 100)
     return, (hours[1] - hours[0])*60.0 + minutes[1] - minutes[0]
  ENDIF 
  
;; if timechange is still greater than 2400 than dt must be greater than one day!
;; and this may not work
;; if it is exactly one day, maybe we can use that??
  IF timechange EQ 10000 OR times[1]-times[0] EQ 10000 THEN return, 1440

  print, "ERROR : Model time step is greater than 1 day, we can't do anything with this!"
  print, "  Timestep 1 = ",strcompress(ulong64(times[0])), $
         "     Timestep 2 = ", strcompress(ulong64(times[1]))

END


;; key
; 0     1     2    3   4    5  6   7   8  9 10 11 12 13  14     15      16     17
;soil,class,sand,silt,clay,ks,vga,vgn,ts,tr,Ts, H,LE, G,STC(1),SMC(1),runoff,drainage
PRO convOUTS2one, outputfile, rosfile, getDay=getDay, forceDay=forceDay

  IF n_elements(outputfile) EQ 0 THEN outputfile="combinedOut"
  IF N_elements(rosfile) EQ 0 THEN rosfile="newRosetta.txt"
  IF NOT keyword_set(getDay) THEN getDay=626

  day=getDay
; Ts, H, LE, G, STC(1), SMC(1)
  varCol=[2,6,7,8,10,18]
  nVar=n_elements(varCol)
  offset=10 ; (soildex,class,sand,silt,clay,ks,vga,vgn,ts,tr)
  results=fltarr(nVar+offset+2) ;parameters, variables, runoff1, runoff2

  files=file_search("out_*_*")
  junk=load_cols(files[0], tmpdata)
  IF n_elements(tmpdata[*,0]) LT 27 THEN results=fltarr(nVar+offset) ;parameters, variables

  nfiles=n_elements(files)

;; These are columns in the rosetta database file
  soildex=0
  sand   =3
  silt   =4
  clay   =5
  ks     =7
  ts     =8
  tr     =9
  vga    =10
  vgn    =11

;; read in the rosetta database info
  junk=load_cols(rosfile, params)

  openw, oun, /get, outputfile
  
  junk=load_cols(files[0], data, /double)
  
  dt=finddt(data[0,1:10])
  perday=1440.0/dt
  print, perday, dt
  FOR i=0, nfiles-1 DO BEGIN
     ;; read the current datafile
     j=load_cols(files[i], data)
     ;; determine if noah was only outputing a subset of the data
     IF n_elements(data[0,*]) LT 20000 AND NOT keyword_set(forceDay) THEN getDay=day-624 ELSE getDay=day
     ;; find the relavent times
;     IF (n_elements(data[0,*]) LT 40000 AND NOT n_elements(data[0,*]) LT 20000) THEN $
;       perday=48.0 ELSE perday=480.0
     index=where(fix(lindgen(n_elements(data[0,*]))/perday) EQ getDay)

;; grab data
     IF index[0] NE -1 THEN BEGIN
        index=index[240*(perDay/480.0):299*(perday/480.0)] ; mid day values (22-27 or 220-279)
        FOR j=0, nVar-1 DO BEGIN 
           results[j+offset]=mean(data[varCol[j],index])
        endFOR
     ENDIF

     ;; get the current soil index from the file name
     curSoildex=(strsplit(files[i], '_', /extract))[2]

     ;; get the index value of the current soil texture class from filename
     class=textIndex((strsplit(files[i], '_', /extract))[1])

     ;; find that soil in the rosetta database
     index2=where(params[soildex,*] EQ curSoildex)
     IF index2[0] NE -1 THEN BEGIN 
        curparams=params[*,index2] 
     endIF ELSE print, "ERROR ",curSoildex," not found"
     
;; all the rest of the data
     IF index[0] NE -1 AND index2[0] NE -1 THEN BEGIN 
        results[0:offset-1]=curparams[[soildex, class, sand, silt, clay, $
                                       ks, vga, vgn, ts, tr]]
        results[1]=class
        runoffoffset=2
        IF n_elements(data[*,0]) GT 27 THEN BEGIN 
           results[nVar+offset] = total(data[26,*])/(total(data[3,*])/1000.0)
           results[nVar+offset+1] = total(data[27,*])/(total(data[3,*])/1000.0)
           runoffoffset=0
        endIF 
        printf, oun, results, $
                format='(2I8,'+strcompress(offset+nVar-runoffoffset, /remove_all)+'F15.8)'
     ENDIF 
     IF i MOD (nfiles/100) EQ 0 THEN print, round((float(i)/nfiles)*100), "%"
  ENDFOR

  close, oun
  free_lun, oun
END

