;; randomly select n soils from each soil texture class and compute the
;; r^2 value for soil texture class.
;;
;; do this 1000 times and take the average r2 value (and plot all of them)

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



FUNCTION calcRandStats, inputfile, means=means, $
                        seed=seed, var=var, flux=flux, n=n, all=all, minsoil=minsoil

  junk=load_cols(inputfile, data)
  SSR=0
  SSTO=0
  sum=0
  nclasses=max(data[1,*])+1
  IF keyword_set(all) THEN n=100
  allIndices=intarr(nclasses, n)
  allIndices[*]=-1
  ; loop through all texture classes picking n random soils
  FOR i=minsoil,nclasses-1 DO BEGIN
     ; find the soils in the current class
     class=where(data[1,*] EQ i)
     nvals=n_elements(class)
;     print, nvals, n
     ; if there are any soils (one class doesn't have any) continue
     IF nvals GT 0 THEN BEGIN 

        ; if there are more than n soils then pick all of them
        IF nvals LE n THEN BEGIN 
           index=indgen(nvals) 

        ; else pick them randomly
        endIF ELSE BEGIN 
           index=round(randomu(seed, n)*(nvals-1))
;           print, index
;           print, "---------------------"
;           print, class[index]
           tmp=bytarr(nvals)
           tmp[index]++
;           print, n_elements(where(tmp GT 1))
           nvals=n
           
        ENDELSE

        ; collect the list of soils
        allIndices[i,0:nvals-1]=class[index]
     ENDIF
  ENDFOR 

  ; compute the grand average for calculating SSTO
  ave=mean(data[flux, allIndices[where(allIndices NE -1)]])
  j=minsoil
  allSSR=0
  allSSTO=0
;  print, nclasses
  FOR i=minsoil, nclasses-1 DO BEGIN
     index=where(allIndices[i,*] NE -1)
     IF index[0] NE -1 THEN BEGIN
;        print, allIndices[i,index]
        index=allIndices[i,index]
        SSR+=total((means[j]-data[flux,index])^2)
        SSTO+=total((ave-data[flux,index])^2)

;; debugging
;        curSSR =mean((means[j]-data[flux,index])^2)
;        curSSTO= mean((ave-data[flux,index])^2)
;        print, j, ave, mean(data[flux,index]), means[j], curSSR, curSSTO, 1-curSSR/curSSTO
;        allSSR=[allSSR,curSSR]
;        allSSTO=[allSSTO,curSSTO]
        j++ ; because means only contains a value for the soils that exist
     endIF

  ENDFOR

;  allSSR=allSSR[1:n_elements(allSSR)-1]
;  allSSTO=allSSTO[1:n_elements(allSSTO)-1]
  r2=1-(SSR/SSTO)

;  print, SSR, SSTO
;  print, r2
;  print, mean(1-(allSSR/allSSTO))
;  plot, 1-(allSSR/allSSTO)
;  oplot, [0,20], [r2,r2]
;  wait, 1
;  stop
  return, r2
END

FUNCTION readMeans, fluxCol
  IF file_test("means") THEN BEGIN
     junk=load_cols("means", data)
     return, data[*,fluxCol-10]
  ENDIF
  vars=[2,6,7,8,10,18]
  flux=vars[fluxCol-10]

  namelist="SoilNames.txt"
  openr, un, /get, namelist
  line=""
  dat=0
  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     print, line
     dat=[dat,getData("standards/"+line, flux)]
  ENDWHILE  
  dat=dat[1:n_elements(dat)-1]
  print, dat
  return, dat
END


PRO randr2Stats, inputfile, varCol=varCol, fluxCol=fluxCol, all=all, minsoil=minsoil


  IF n_elements(inputfile) EQ 0 THEN inputfile="combinedOut"
  IF NOT keyword_set(varCol) THEN varCol=1
  IF NOT keyword_set(fluxCol) THEN fluxCol=12
  IF NOT keyword_set(minsoil) THEN minsoil=0
  n=1000
  IF keyword_set(all) THEN n=1
  nsoils=40
  r2vals=fltarr(n)

  means=readMeans(fluxCol)

  seed=1243
  FOR i=0,n-1 DO BEGIN

     r2vals[i]=calcRandStats(inputfile, seed=seed, var=varcol, $
                             flux=fluxCol, n=nsoils, means=means, all=all, minsoil=minsoil)
  endFOR

  IF NOT keyword_set(all) THEN BEGIN 
     plot, r2vals
     ave=mean(r2vals)
     oplot, [0,n],[ave,ave],l=1
     print, ave, stdev(r2vals)
  endIF ELSE print, r2vals

END
