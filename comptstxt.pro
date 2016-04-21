;+
; NAME: compTsTxt
;
; PURPOSE: Compare Ts derived SHPs with texture class average derived SHPs
;
; CATEGORY: noah output manipulation
;
; CALLING SEQUENCE: compTsTxt, outPattern=outPattern, SHPdata=SHPdata
;
; INPUTS: 
;
; OPTIONAL INPUTS:
;       outPattern - set this keyword to a string that defines the pattern file_search
;                    should use to find the noah output files.  default="out_*"
;       SHPdata    - set this keyword to the file naming the SHP data file
;                    default=file_search("*.data")[0]
;
; KEYWORD PARAMETERS: 
;
; OUTPUTS:
;       outfile - text file with a list of SHP values and Ts errors from a randomly
;                 choosen "true" Ts.
;                 default name="outputfile"
;       answerfile - text file containing the "true" SHP values used
;                 default name="answerfile"
;
; OPTIONAL OUTPUTS:
;       theAnswer - set this keyword to print the inverted SHPs,
;                 texture class SHPs, and "true" SHPs
;
; COMMON BLOCKS: <none>
;
; SIDE EFFECTS: <none>
;
; RESTRICTIONS: <none>
;
; PROCEDURE:
;         Read in all noah output files
;         randomly select one as "truth"
;         add 1K RMS error to the "truth" Ts series
;         measure the distance between all SHP runs and "true" Ts
;         find the minimum distance, these are our inverted SHPs
;         OPTIONALLY print, inverted SHPs, textureclass SHPs, "true" SHPs
;
; EXAMPLE: compTsTxt, outPattern="out_sandyloam_*", SHPdata="sandyloam.data",
;                     outfile="TsErrors", answerFile="secret"
;
; MODIFICATION HISTORY:
;         5/20/2005 - EDG - original
;
;-


;; write the (potentially secret) answer file.  
PRO write_answerfile, err, eAll, eFlux, trueSHPs, shps, answerFile, bigoun, finalonly=finalonly

  txterr=err[n_elements(err)-1]
  txteAll=eAll[n_elements(eAll)-1]
  txteFlux=eFlux[n_elements(eFlux)-1]

  err=err[0:n_elements(err)-2]
  eAll=eAll[0:n_elements(eAll)-2]
  eFlux=eFlux[0:n_elements(eFlux)-2]


  index=where(err EQ min(err))
  IF n_elements(index) GT 1 THEN BEGIN 
     print, "multiple values match, using the first match"
     FOR i=0,n_elements(index)-1 DO $
       print, err[index[i]], shps[5:*,index[i]]
     index=index[0]
  endIF
  
  
  textureSHPs=[1.45,0.0269, (4.4e-6)*8640000, 0.387,0.039]
  IF NOT keyword_set(finalonly) THEN BEGIN 
     openw, oun, /get, answerFile
     printf, oun, "Ts error", err[index]
     printf, oun, "true SHPs   ", trueSHPs[5:*]
     printf, oun, "inverse SHPs", shps[5:*,index]
     printf, oun, "texture SHPs", textureSHPs
     printf, oun, "Texture SHP Error =        ",sqrt( $
             (trueSHPs[5]-textureSHPs[0])^2 + $
             (trueSHPs[6]-textureSHPs[1])^2 + $
             (alog10(trueSHPs[7])-alog10(textureSHPs[2]))^2 + $
             (trueSHPs[8]-textureSHPs[3])^2 + $
             (trueSHPs[9]-textureSHPs[4])^2)
     
     printf, oun, "Best Fit SHP Error =       ", sqrt( $
             (trueSHPs[5]-shps[5,index])^2 + $
             (trueSHPs[6]-shps[6,index])^2 + $
             (alog10(trueSHPs[7])-alog10(shps[7,index]))^2 + $
             (trueSHPs[8]-shps[8,index])^2 + $
             (trueSHPs[9]-shps[9,index])^2)
     
     close, oun
     free_lun, oun
  ENDIF

  IF n_elements(bigoun) GT 0 THEN $
    printf, bigoun, err[index], eAll[index], eflux[index], $
            trueSHPs[5:*], shps[5:*,index], textureSHPs, $
            txterr, txteAll, txteFlux, format='(25F20.5)'
END


FUNCTION read_data, files, col=col
  IF NOT keyword_set(col) THEN col=2
  ;; read in all input file Ts data
  junk=load_cols(files[0], curdata)

  n_files=n_elements(files)
  ;; read the first file to find out how many time steps there are
  data=fltarr(n_elements(curdata[0,*]), n_files)
  data[*,0]=curdata[col,*]

  ;; store soil database label in an array
  soils=intarr(n_files)
  soils[0]=(strsplit(files[0], '_', /extract))[2]

  FOR i=1, n_files-1 DO BEGIN
     junk=load_cols(files[i], curdata)
     data[*,i]=curdata[col,*]

     soils[i]=(strsplit(files[i], '_', /extract))[2]
     IF ((float(i)/(n_files-1))*100 MOD 10) lt 0.32 THEN $
       print, round(100*(float(i)/(n_files-1))), '%' ;, (float(i)/(n_files-1))*1000 MOD 100
;     plot, curdata[18,*], yr=[0,0.4]
;     wait, 0.1
  ENDFOR

  return, {data:data, soils:soils}
END


;; compute error between trueTs and data values
;;  write an error file that contains error-Ts pairs
FUNCTION write_errfile, outfile, n_files, trueTs, data, shps, key=key, truth=truth, $
  index=index, col=col, finalonly=finalonly
  err=dblarr(n_files)
  IF NOT keyword_set(col) THEN col=2
  nvals=n_elements(trueTs)

  textureSHPs=[1.45,0.0269, (4.4e-6)*8640000, 0.387,0.039]
  class=(strsplit(((file_search("out_*"))[0]), '_', /extract))[1]
  IF file_test("classAverage") THEN BEGIN 
     junk=load_cols("classAverage", txtAve) 
  ENDIF ELSE BEGIN 
     junk=load_cols(file_search(class, /fold_CASE), txtAve)
  ENDELSE

  IF keyword_set(index) THEN txtAve=txtAve[*,index]
  sz=size(txtAve)
  nelem=min([sz[2],n_elements(trueTs)])

  IF NOT keyword_set(finalonly) THEN $
    openw, oun, /get, outfile
  txtErr=sqrt(total((trueTs[0:nelem-1]-txtAve[col,0:nelem-1])^2, /double)/nvals)
  IF NOT keyword_set(finalonly) THEN $
    printf, oun, txtErr, textureSHPs, format='(12F20.4)'  

  IF keyword_set(key) AND NOT keyword_set(finalonly) THEN $
    printf, oun, sqrt(total((trueTs-data[*,key])^2, /double)/nvals), $
            shps[5:*,key], format='(12F20.4)' 

  IF keyword_set(truth) AND NOT keyword_set(finalonly) THEN $
    printf, oun, sqrt(total((trueTs-data[*,truth])^2, /double)/nvals), $
            shps[5:*,truth], format='(12F20.4)' 

  FOR i=0,n_files-1 DO BEGIN
     err[i]=sqrt(total((trueTs-data[*,i])^2, /double)/nvals)
     IF NOT keyword_set(finalonly) THEN printf, oun, err[i], shps[5:*,i], format='(12F20.4)'
  ENDFOR
  IF NOT keyword_set(finalonly) THEN BEGIN 
     close, oun
     free_lun, oun
  ENDIF 
  
  return, [err,txtErr]
END


;; MAIN ROUTINE
PRO compTsTxt, outPattern=outPattern, SHPdata=SHPdata, $
               outfile=outfile, answerFile=answerFile, theAnswer=theAnswer, $
               count=count, modis=modis, all=all, finalonly=finalonly, truthdir=truthdir

  IF NOT keyword_set(count) THEN count=1
  IF NOT keyword_set(outPattern) THEN outPattern="out_*"
  IF NOT keyword_set(SHPdata) THEN SHPdata=file_search("*.data")
  IF NOT keyword_set(outfile) THEN outfile="outfile"
  IF NOT keyword_set(answerFile) THEN answerFile="answerfile"
  
  files=file_search(outPattern)
  n_files=n_elements(files)
  IF keyword_set(all) THEN count=n_files
  info=read_data(files)
  fluxinfo=read_data(files, col=7)
  data=info.data
  fluxdata=fluxinfo.data
  soils=info.soils

  IF keyword_set(truthdir) THEN BEGIN
     truthfiles=file_search(truthdir+'/'+outPattern)
     print, truthfiles[0]
     truthn_files=n_elements(truthfiles)
     IF keyword_set(all) THEN count=truthn_files
     truthinfo=read_data(truthfiles)
     truthdata=truthinfo.data
     truthfluxinfo=read_data(truthfiles, col=7)
     truthfluxdata=truthfluxinfo.data
  ENDIF ELSE BEGIN 
     truthn_files=n_files
     truthfiles=files
     truthdata=data
     truthfluxdata=fluxdata
  ENDELSE

  ;; find periods of maximum variability resulting from SHPs
  nTimes=n_elements(data[*,0])
  variation=fltarr(nTimes)
  FOR i=0,nTimes-1 DO BEGIN 
     variation[i]=stdev(data[i,*]) ; variability is defined by the standard deviation
  ENDFOR

  ;; find the top 10 percent of variation
  top10=percentiles(variation, value=[0.9])
  keydays=where(variation GT top10)


  ;; read in the SHP data from a *.data file output from noahSoilswTexture
  ;;shpdata format = columns,
  ;;  [soilIndex, 0.9,0.9,0.9,0.9, n, alpha, Ks, Ts, Tr]
  ;;  [    0       1   2   3   4   5    6     7   8   9]
  IF n_elements(SHPdata) GT 1 THEN BEGIN
     texture=(strsplit(files[0], '_', /extract))[1]
     SHPdata=file_search(texture+'.data', /fold_case)
  ENDIF

  junk=load_cols(SHPdata, shps)
  
  tdex=sort(soils)
  soils=soils[tdex]
  data=data[*,tdex]
  fluxdata=fluxdata[*,tdex]
  truthdata=truthdata[*,tdex]
  truthfluxdata=truthfluxdata[*,tdex]
  files=files[tdex]

  sdex=sort(shps[0,*])
  shps=shps[*,sdex]

  IF max(shps[0,*]-soils) GT 0 THEN print, "ERROR, databases don't match"

  truthSeed=strmid(systime(),14,2)+strmid(systime(), 17,2)
  randomSeed=randomn(20+fix(strmid(systime(),14,2))+fix(strmid(systime(), 17,2)))
  openw, bigoun, /get, "full"+outfile

  times=lindgen(ntimes) MOD 48
  index=where(times eq 22)      ; modis times
  IF NOT keyword_set(modis) THEN index=keydays
;  stop
  ;; loop through n times selecting random SHPs, computeing Ts error vs all other SHPs
  ;;  find the minimum and write it to a file, also write all other data to files
  FOR counter=0,count-1 DO BEGIN 
     IF keyword_set(all) THEN truth = counter ELSE $
       truth=round(randomu(truthSeed)*truthn_files)
;     randomSeed=randomn(randomSeed)

; generates random 1K RMS noise
;     randomErr=fltarr(nTimes)
;     FOR i=0,nTimes-1 DO randomErr[i]=randomn(randomSeed) 
     randomErr=randomn(randomSeed, nTimes)

     trueTs=truthdata[*,truth]+randomErr
     trueFlux=truthfluxdata[*,truth]
     trueFile=truthfiles[truth]

;; rule to extract soil index from output file name
;     tmpindex=strmid(trueFile, 14,4)
     tmpindex=fix((strsplit(trueFile, '_', /extract))[2])

     trueRow=where(shps[0,*] EQ tmpindex)
     IF trueRow[0] NE -1 THEN BEGIN 
        trueSHPs=shps[*,trueRow]

        err=write_errfile(outfile+strcompress(counter, /remove_all), n_files, $
                          trueTs[index], data[index,*], shps, index=index, finalonly=finalonly)
        best=where(err EQ min(err))
        errALL=write_errfile("all"+outfile+strcompress(counter, /remove_all), n_files, $
                             trueTs, data, shps, key=best, $
                             truth=truth, finalonly=finalonly)
        errALLflux=write_errfile("flux"+outfile+strcompress(counter, /remove_all), n_files, $
                                 trueFlux[index], fluxdata[index, *], shps, key=best, truth=truth, $
                                 col=7, finalonly=finalonly, index=index)
        write_answerfile, err, errAll, errAllFlux, trueSHPs, shps, $
                          answerFile+strcompress(counter, /remove_all), $
                          bigoun, finalonly=finalonly
     ENDIF

  END
  close, bigoun
  free_lun, bigoun

END 

PRO batchcomp, testdir, truthdir
  cd, current=old, testdir
  dirs=file_search("ihop*")
  print, dirs
  FOR i=0, n_elements(dirs)-1 DO BEGIN
     cd, dirs[i], current=last
     print, dirs[i]
     print, testdir+'/'+dirs[i]
     IF n_elements(truthdir) NE 0 THEN BEGIN 
        truedir=truthdir+'/'+dirs[i]
        print, truedir
     ENDIF 
     comptstxt, truthdir=truedir, /all, $
       /modis, outfile="modisoutput", answerfile="modisanswer"
     comptstxt, truthdir=truedir, /all
     cd, last
  ENDFOR
  cd, old
END 

PRO batchbatch, two=two
  testdirs=['/Volumes/hydra/simpleReal/noahmod/modzo/','/Volumes/hydra/simpleReal/noahmod/modalbedo/']
  testdirs2=['/Volumes/Home/gutmann/Desktop/SHP-Ts/working/agu-ts-shp-potential/modeling/noah/modveg','/Volumes/Home/gutmann/Desktop/SHP-Ts/working/agu-ts-shp-potential/modeling/noah/modrs']
  truthdir='/Volumes/hydra/simpleReal/noahinputfiles/'

  IF keyword_set(two) THEN testdirs=testdirs2
  batchcomp, testdirs[0], truthdir
  batchcomp, testdirs[1], truthdir

enD

