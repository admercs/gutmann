
PRO r2classStats, rosfile, outfile, resfile=resfile, varCol=varCol
  IF NOT keyword_set(varCol) THEN varCol=7
  IF N_elements(rosfile) EQ 0 THEN rosfile="newRosetta.txt"
  files=file_search("out_*_*")
  nfiles=n_elements(files)

  junk=load_cols(rosfile, params)
  
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

  IF keyword_set(resfile) THEN BEGIN
     junk=load_cols(resfile, resultsData)
  ENDIF ELSE BEGIN 

     resultsData=fltarr(10,nfiles)
     resultsData[*]=-999.99
     
     
     FOR i=0,nfiles-1 DO BEGIN
        ;; read the current datafile
        j=load_cols(files[i], data)
        ;; determine if noah was only outputing a subset of the data
        IF n_elements(data[0,*]) LT 50000 THEN getDay=2 ELSE getDay=626
        ;; find the relavent times
        index=where(fix(lindgen(n_elements(data[0,*]))/480.) EQ getDay)

;; latent heat data
        IF index[0] NE -1 THEN $
          resultsData[0,i]=mean(data[varCol,index])

        ;; get the current soil index from the file name
        curSoildex=(strsplit(files[i], '_', /extract))[2]
        ;; find that soil in the rosetta database
        index=where(params[soildex,*] EQ curSoildex)
        IF index[0] NE -1 THEN BEGIN 
          curparams=params[*,index] 
       endIF ELSE print, "ERROR ",curSoildex," not found"
        
;; all the rest of the data
        IF index[0] NE -1 THEN $
          resultsData[1:9,i]=curparams[[soildex, sand, silt, clay, ks, vga, vgn, ts, tr]]
     ENDFOR
     outfile="NEWRESULTS"+strcompress(varCol, /remove_all)
     openw, oun, /get, outfile
     printf, oun, resultsData, format='(10F15.8)'
     close, oun
  ENDELSE 
     
  paramNames=['Sand', 'Silt', 'Clay', 'K_s', 'alpha', 'n', 'Ts', 'Tr']
  resultsData[5,*]=alog(resultsData[5,*])
  resultsData[7,*]=1/(resultsData[7,*])


  FOR i=2,9 DO BEGIN
     
     output=regress(resultsData[i,*], transpose(resultsData[0,*]), correlation=rVal)
     print, paramNames[i-2], rVal^2
     
  END
  dex=[2,3]
  output=regress(resultsData[dex,*], transpose(resultsData[0,*]), correlation=rVal, mcorr=R)
  print, paramNames[dex-2], R^2
  dex=[2,4]
  output=regress(resultsData[dex,*], transpose(resultsData[0,*]), correlation=rVal, mcorr=R)
  print, paramNames[dex-2], R^2
  dex=[3,4]
  output=regress(resultsData[dex,*], transpose(resultsData[0,*]), correlation=rVal, mcorr=R)
  print, paramNames[dex-2], R^2
  dex=[2,3,4]
  output=regress(resultsData[dex,*], transpose(resultsData[0,*]), correlation=rVal, mcorr=R)
  print, paramNames[dex-2], R^2

  dex=[5,6]
  output=regress(resultsData[dex,*], transpose(resultsData[0,*]), correlation=rVal, mcorr=R)
  print, paramNames[dex-2], R^2
  dex=[5,7]
  output=regress(resultsData[dex,*], transpose(resultsData[0,*]), correlation=rVal, mcorr=R)
  print, paramNames[dex-2], R^2
  dex=[6,7]
  output=regress(resultsData[dex,*], transpose(resultsData[0,*]), correlation=rVal, mcorr=R)
  print, paramNames[dex-2], R^2
  dex=[5,6,7]
  output=regress(resultsData[dex,*], transpose(resultsData[0,*]), correlation=rVal, mcorr=R)
  print, paramNames[dex-2], R^2
  dex=[5,6,7,8,9]
  output=regress(resultsData[dex,*], transpose(resultsData[0,*]), correlation=rVal, mcorr=R)
  print, paramNames[dex-2], R^2
  
END 

  
