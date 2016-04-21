;; randomly select n soils from each soil texture class and compute the
;; r^2 value for soil texture class.
;;
;; do this 1000 times and take the average r2 value (and plot all of them)

FUNCTION getData, fname, varCol, getday=getday
  junk=load_cols(fname, curData)

  ;; determine if noah was only outputing a subset of the data
;;  IF n_elements(curData[0,*]) LT 50000 THEN getDay=2 ELSE getDay=626
  IF NOT keyword_set(getday) THEN getday=626-365

  ;; find the relavent times
  index=where(fix(lindgen(n_elements(curData[0,*]))/48.) EQ getDay)
  
  IF n_elements(index) GT 40 THEN index=index[22:28] ;11AM to 2PM
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

FUNCTION readMeans, fluxCol, getday=getday
  IF file_test("means") THEN BEGIN
     junk=load_cols("means", data)
     return, data[*,fluxCol-10]
  ENDIF
  vars=[2,6,7,8,10,18]
  flux=vars[fluxCol-10]

  namelist="../SoilNames.txt"
  openr, un, /get, namelist
  line=""
  dat=0
  WHILE NOT eof(un) DO BEGIN
     readf, un, line
;     print, line
     dat=[dat,getData(strupcase(strcompress(line, /remove_all)), flux, getday=getday)]
  ENDWHILE  
  dat=dat[1:n_elements(dat)-1]
  print, dat
  return, dat
END


PRO randr2Stats, inputfile, varCol=varCol, fluxCol=fluxCol, all=all, $
                 minsoil=minsoil, getday=getday, result


  IF n_elements(inputfile) EQ 0 THEN inputfile="combinedOut"
  IF NOT keyword_set(varCol) THEN varCol=1
  IF NOT keyword_set(fluxCol) THEN fluxCol=12
  IF NOT keyword_set(minsoil) THEN minsoil=0
  n=1000
  IF keyword_set(all) THEN n=1
  nsoils=40
  r2vals=fltarr(n)

  means=readMeans(fluxCol, getday=getday)

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

  result=ave
END

PRO multiSiteRandDriver, varcol=varcol, fluxcol=fluxcol, minsoil=minsoil, thisdir=thisdir
  dirs=file_search('ihop*')
  dirs=dirs[[1,2,0,3,4,5,6,7,8,9,10]] ; put bss and bsg up front

  day=[626-365,192,50,38,37,48,49,76,48,48,48]
  day=[626-365,192,30, 30, 37, 38, 38, 30, 14, 46, 46]
  IF keyword_set(thisdir) THEN BEGIN 
     dirs=['.']
     day[*]=day[thisdir]
  ENDIF 
  stcr2=fltarr(n_elements(dirs))

  FOR i=0, n_elements(dirs)-1 DO BEGIN
     cd, current=olddir, dirs[i]

     print, dirs[i]
     file=(file_search('comb*'))[0]
     file='convouts'
     randr2stats, file, varcol=varcol, fluxcol=fluxcol, minsoil=minsoil, getDay=day[i], result

     stcr2[i]=result
     cd, olddir
  ENDFOR

  print, strjoin(string(stcr2, format='(F5.2)'), ' & ')
END

;; use a fourth order polynomial to calculate r^2 for LH against sa.si.cl, 1/n, and log(ks)
;;  use keyword nosand to ignore the sand class
;;  use keyword hiks to ignore very low ks values (excessive runoff)
;;  use keyword fluxcol to look at other fluxes, 10=Ts, 11=SH, 12=LH...
PRO simpler2stats, nosand=nosand, hiks=hiks, fluxcol=fluxcol, thisdir=thisdir
  dirs=file_search('ihop*')
  dirs=dirs[[1,2,0,3,4,5,6,7,8,9,10]] ; put bss and bsg up front

  IF keyword_set(thisdir) THEN dirs=['.']
  
  IF NOT keyword_set(nosand) THEN nosand =0
  IF keyword_set(nosand) THEN print, 'not using sand class', nosand
  ranges=fltarr(n_elements(dirs),2)
  output=fltarr(n_elements(dirs),3)
  classmeds=fltarr(12)

  vars=[1,5,7]
  IF NOT keyword_set(fluxcol) THEN fluxcol=12 ; LH in convouts
  FOR i=0, n_elements(dirs)-1 DO BEGIN
     cd, dirs[i], current=olddir
     
     file=(file_search('comb*'))[0]
     file='convouts'
     
     junk=load_cols(file, data)
     
     IF keyword_set(nosand) THEN BEGIN
        index=where(data[1,*] NE 0)
        IF index[0] NE -1 THEN data=data[*,index]
     ENDIF
     
     data[5,*]=alog10(data[5,*])
     data[7,*]=1-1.0/data[7,*]
     
     IF keyword_set(hiks) THEN BEGIN
        index=where(data[5,*] GT 0)
        IF index[0] NE -1 THEN data=data[*,index]
     ENDIF

     FOR var=0,n_elements(output[0,*])-1 DO BEGIN

        junk=regress([data[vars[var],*],data[vars[var],*]^2, $
                      data[vars[var],*]^3, data[vars[var],*]^4], $
                     transpose(data[fluxcol,*]), mcorr=corr)
        output[i,var]=corr^2
        IF var EQ 0 THEN BEGIN
           junk=regress([data[2:3,*],data[2:3,*]^2,data[2:3,*]^3,data[2:3,*]^4], $
                        transpose(data[fluxcol,*]),mcorr=corr)
           output[i,var]=corr^2
        ENDIF
        IF var EQ 0 THEN BEGIN 
           nclasses=0
           FOR class=nosand, 11 DO BEGIN
              tmp=where(data[1,*] EQ class)
              IF tmp[0] NE -1 THEN BEGIN
                 nclasses++
;                 ranges[i,0]+=stdev(data[fluxcol,tmp])
                 ranges[i,0]+=(max(data[fluxcol,tmp])-min(data[fluxcol,tmp]))
                 classmeds[class]=median(data[fluxcol,tmp])
              ENDIF 
           ENDFOR
           ranges[i,0]/=nclasses
;           ranges[i,1]=stdev(classmeds[where(classmeds NE 0)])
           ranges[i,1]=max(classmeds[where(classmeds NE 0)])-min(classmeds[where(classmeds NE 0)])
;           print, stdev(classmeds[where(classmeds NE 0)]), min(classmeds[where(classmeds NE 0)]), max(classmeds[where(classmeds NE 0)])-min(classmeds[where(classmeds NE 0)])
        ENDIF 
     ENDFOR

     cd, olddir
  endFOR

  FOR i=0,n_elements(output[0,*])-1 DO $
    print, strjoin(string(output[*,i], format='(F5.2)'),' & ')
  
  print, total(output,1)/n_elements(dirs)

  print, strjoin(string(ranges[*,0], format='(F9.2)'),' & ')
  print, strjoin(string(ranges[*,1], format='(F9.2)'),' & ')

END

