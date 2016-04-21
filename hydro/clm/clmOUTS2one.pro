FUNCTION textIndex, texture
  CASE strlowcase(texture) OF 
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


PRO clmOUTS2one, outputfile, rosfile, getDay=getDay

  IF n_elements(outputfile) EQ 0 THEN outputfile="combinedOut"
  IF N_elements(rosfile) EQ 0 THEN rosfile="newRosetta.txt"
  IF NOT keyword_set(getDay) THEN getDay=626

  day=getDay
; Ts, H, LE, G, STC(1), SMC(1)
  varCol=[1,2,3,4,5,15]
  nVar=n_elements(varCol)
  offset=10 ; (soildex,class,sand,silt,clay,ks,vga,vgn,ts,tr)
  results=fltarr(nVar+offset)

  files=file_search("out_*_*")
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
  variables=['time','TG','FSH','FGEV','FGR','TSOI','H2OSOI']

;; read in the rosetta database info
  junk=load_cols(rosfile, params)

  openw, oun, /get, outputfile
  
  FOR i=0, nfiles-1 DO BEGIN
     ;; read the current datafile
     data=readNCdata(files[i], variables)
     data=data.data

     ;; find the relavent times
     index=where(fix(lindgen(n_elements(data[0,*]))/48.) EQ getDay)
     
;; grab data
     IF index[0] NE -1 THEN BEGIN
;        index=index[22:28] 
        index=index[28:33] ;; clm has MUCH more LE late in the afternoon
        print, "WARNING: COMPUTING STATS BASED ON 28:33 (2PM-5PM) NOT 22:28 (11AM-2:30PM)"
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
        printf, oun, results, $
                format='(2I8,'+strcompress(offset-2+nVar, /remove_all)+'F15.8)'
     ENDIF 
     IF i MOD (nfiles/100) EQ 0 THEN print, round((float(i)/nfiles)*100), "%"
  ENDFOR

  close, oun
  free_lun, oun
END

