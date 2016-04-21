FUNCTION getData, fname, varCol
  junk=load_cols(fname, curData)

  ;; determine if noah was only outputing a subset of the data
  IF n_elements(curData[0,*]) LT 50000 THEN getDay=2 ELSE getDay=626
  
  ;; find the relavent times
  index=where(fix(lindgen(n_elements(curData[0,*]))/480.) EQ getDay)
  
  IF n_elements(index) GT 400 THEN index=index[220:280] ;11AM to 2PM
  IF index[0] NE -1 THEN $
    return, mean(curData[varCol,index])
  return, -1
END

PRO r2textClass, namelist, varCol=varCol
  IF NOT keyword_set(varCol) THEN varCol=7
  IF n_elements(namelist) EQ 0 THEN namelist="SoilNames.txt"
  
  openr, un, /get, namelist
  line=""

  soil=0

  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     files=file_search('out_'+line+'_*')

     data=fltarr(3,n_elements(files))
     FOR i=0, n_elements(files)-1 DO BEGIN

        ;; get the current soil index from the file name
        curSoildex=(strsplit(files[i], '_', /extract))[2]
        data[0,i]=curSoildex
        data[1,i]=soil

        ;; read the data
        data[2,i]=getData(files[i], varCol)
     endFOR
     IF n_elements(masterdata) LT 2 THEN masterdata=data ELSE $
       masterdata=[[masterdata],[data]]
     
     tmp=getData(line, varCol)
     IF n_elements(classData) EQ 0 THEN classData=tmp ELSE $
       classData=[classData,tmp]

     soil++
  ENDWHILE
  data=masterdata

  ave=mean(data[2,*])
  SSTO=total((data[2,*]-ave)^2)
  SSR=0
  FOR i=0, soil-1 DO BEGIN 
     index=where(data[1,*] EQ i)
     SSR+=total((data[2,index]-classData[i])^2)
  endFOR
  
  print, 'ALL SOILS : ', 1-SSR/SSTO

  data=masterdata[*,where(masterdata[1,*] GT 0)]
  ave=mean(data[2,*])
  SSTO=total((data[2,*]-ave)^2)
  SSR=0
  FOR i=1, soil-1 DO BEGIN 
     index=where(data[1,*] EQ i)
     SSR+=total((data[2,index]-classData[i])^2)
  endFOR
  
  print, 'no sand : ', 1-SSR/SSTO

  data=masterdata[*,where(masterdata[1,*] GT 1)]
  ave=mean(data[2,*])
  SSTO=total((data[2,*]-ave)^2)
  SSR=0
  FOR i=2, soil-1 DO BEGIN 
     index=where(data[1,*] EQ i)
     SSR+=total((data[2,index]-classData[i])^2)
  endFOR
  
  print, 'no loamysand : ', 1-SSR/SSTO
  

  data=masterdata[*,where(masterdata[1,*] GT 2)]
  ave=mean(data[2,*])
  SSTO=total((data[2,*]-ave)^2)
  SSR=0
  FOR i=3, soil-1 DO BEGIN 
     index=where(data[1,*] EQ i)
     SSR+=total((data[2,index]-classData[i])^2)
  endFOR
  
  print, 'no sandyloam : ', 1-SSR/SSTO
  

  data=masterdata

  outfile='outfile_'+strcompress(varCol, /remove_all)
  openw, oun, /get, outfile+".class"
  printf, oun, classData
  openw, oun2, /get, outfile+".data"
  printf, oun, data
  
  close, oun, oun2
  free_lun, oun, oun2
END 

