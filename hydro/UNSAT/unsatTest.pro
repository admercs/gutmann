;; read a master file and replace the lines that relate to the
;;   VG parameters with new values for n, alpha, and Ks in a new file
PRO makeInputFile, master, newfile, n, alpha, Ks

  openr, un, /get, master 
  openw, oun, /get, newfile

  line=''
  i=0
  WHILE NOT eof(un) DO begin
     readf, un, line
;; replace the Van Genuchtan parameters line
;;   leaving theta_r line[1] and theta_s line[0] as is
     IF i EQ 30 THEN BEGIN 
        line=strsplit(line, ',', /extract)
        printf, oun, line[0], ',', line[1], ',', $
                strcompress(alpha), ',', strcompress(n), ' VG params'
        line=''
;; replace the Mualem/Van Genuchtan parameters line
;;   leaving the specification of mualem parameterization (line[0])
     ENDIF ELSE IF i EQ 32 THEN BEGIN
        line=strsplit(line, ',', /extract)
        printf, oun, line[0], ',', strcompress(Ks), ',', $
                strcompress(alpha), ',', strcompress(n), $
                ', 0.5   Mualem params'
        line=''
     ENDIF ELSE $
       printf, oun, line     
     i=i+1
  ENDWHILE
  
  close, un, oun
  free_lun, un, oun
END

;; just too easy
PRO runUNSAT, tempfile
  spawn, './din <dinfile; ./unsat <unsatfile; dout <doutfile &>dout.out;'
END
;; just too easy
FUNCTION getTruth, file
  jnk=load_cols(file, data)
  return, data
END

PRO getParams, paramfile=paramfile, $
                    min_n=min_n, max_n=max_n, step_n=step_n, $
                    min_alpha=min_alpha, max_alpha=max_alpha, $
                       step_alpha=step_alpha, $
                    min_Ks=min_Ks, max_Ks=max_Ks, step_Ks=step_Ks
;; if we were giving a parameter file read from that
;; else we will provide default values
  IF keyword_set(paramfile) THEN BEGIN 
     j=load_cols(paramfile, params)
     min_n = params[0]
     max_n = params[1]
     IF params[2]-1 EQ 0 THEN step_n =(max_n-min_n)+1 ELSE $
       step_n= (max_n-min_n)/(params[2]-1)
     
     min_alpha = params[3]
     max_alpha = params[4]
     IF params[5]-1 EQ 0 THEN step_alpha =(max_alpha-min_alpha)+1 ELSE $
       step_alpha= (max_alpha-min_alpha)/(params[5]-1)
     
     min_Ks = params[6]
     max_Ks = params[7]
     IF params[8]-1 EQ 0 THEN step_Ks =(max_Ks-min_Ks)+1 ELSE $
       step_Ks= (max_Ks-min_Ks)/(params[8]-1)
     
;; In case starting and stopping points are the same (e.g. we are no
;; testing one of the parameters
     IF step_n EQ 0 THEN step_n=1
     IF step_alpha EQ 0 THEN step_alpha=1
     IF step_Ks EQ 0 THEN step_Ks=1
     
;; default values
  ENDIF ELSE BEGIN
;;  VG n
;; sand real =3.1769
     min_n=1.10
     max_n=3.4
     step_n=0.1
;;  VG alpha
;; sand real =0.03524
     min_alpha=0.003
     max_alpha=0.040
     step_alpha=0.005
;;  VG Ks
;; sand real =26.78
     min_Ks=0.5
     max_Ks=5
     step_Ks=0.5
  ENDELSE
  
END


;; Compute the Root Mean Square Error between the "truth" and the
;;    current "test"
FUNCTION computeError, test, truth, index=index
  
;; If we don't have the same number of elements in both truth and test
;; then this test run must have failed, so we will check what is
;; available but mark it by returning a negative value.  
  IF n_elements(test) NE n_elements(truth) THEN $
    return, -1* computeError(test, truth[*,0:n_elements(test[2,*])-1], index=index)

  tmp=test[2,*]
  tmp2=truth[2,*]

  IF NOT keyword_set(index) THEN index = indgen(n_elements(tmp2))
  res = sqrt( total(double(tmp[index]-tmp2[index])^2)/n_elements(tmp[index]) )
  return, res
END

FUNCTION getIndex, n_vals
  arr1=indgen(67-61) + 61
  arr2=indgen(94-79) + 79
  arr3=indgen(121-102) + 102
  arr4=indgen(142-127) + 127
  arr5=indgen(163-152) + 152
  arr6=indgen(187-175) + 175

  default=[arr1,arr2,arr3,arr4, arr5, arr6]
  
  IF n_vals LT 187 THEN BEGIN
     finish=where(default GT n_vals-1)
     final=default[0:finish[0]-1]
     return, final
  ENDIF
  return, default
END

FUNCTION getBIGIndex, n_vals
  arr2=indgen(88-85) + 85
  arr3=indgen(113-107) + 107
  arr4=indgen(137-131) + 131
  arr5=indgen(184-179) + 179

  default=[arr2,arr3,arr4, arr5]
  
  IF n_vals LT 184 THEN BEGIN
     finish=where(default GT n_vals-1)
     final=default[0:finish[0]-1]
     return, final
  ENDIF
  return, default
END



PRO unsatTest, master, temp, output, truth, paramFile=paramFile
  IF n_elements(master) EQ 0 THEN master="mhotw.inp"
  IF n_elements(temp) EQ 0 THEN temp="heat2.inp"
  IF n_elements(output) EQ 0 THEN output="testOutput"
  IF n_elements(truthFile) EQ 0 THEN truthFile="mhotw.out"


;; this will be the output file for each simulation
  unsatVals=string((strsplit(temp, '.', /extract))[0])+".out"

;; read in the output values from the master input file this is
;; considered the "truth"
  truth=getTruth(truthFile)

;; Read the parameter space we are going to iterate through
  getParams, paramfile=paramfile, $
             min_n=min_n, max_n=max_n, step_n=step_n, $
             min_alpha=min_alpha, max_alpha=max_alpha, $
             step_alpha=step_alpha, $
             min_Ks=min_Ks, max_Ks=max_Ks, step_Ks=step_Ks

;; Number of steps we are performing for each variable (should equal
;; params[2,5,8] but these may not have been specified).  +1 because
;;    the for loop is inclusive of the end points...
;;    for i=1,10 = 10 iterations not 10-1=9
  xrange=((max_n-min_n)/step_n)     +1
  yrange=((max_alpha-min_alpha)/step_alpha)  +1
  zrange=((max_Ks-min_Ks)/step_Ks)  +1

;; error array stores the important variables
  err=dblarr(xrange, yrange, zrange)
  big_err=dblarr(xrange, yrange, zrange)
  real_big_err=dblarr(xrange, yrange, zrange)

;; subscripts for the error array
  i=0  &  j=0  &  k=0

;; log file to send a simplified text output to.  
  openw, un, /get, 'logfile'

  print, min_n, max_n, step_n, fix(xrange)
  print, min_alpha, max_alpha, step_alpha, fix(yrange)
  print, min_Ks, max_Ks, step_Ks, fix(zrange)
  
  FOR n=min_n, max_n, step_n DO BEGIN 
     FOR alpha=min_alpha, max_alpha, step_alpha DO BEGIN 
        FOR Ks=min_Ks,max_Ks,step_Ks DO BEGIN

;; make the .inp input file based on the master file
           makeInputfile, master, temp, n, alpha, Ks
;; run din, unsat, and dout
           runUnsat, temp
;; get the results
           data=getTruth(unsatVals)

;; compare the results to the "truth" from the master file output           
           err[i,j]=computeError(data, truth)
;; also compare results at only the most sensitive times
           thisindex=getIndex(n_elements(data))
           big_err[i,j]=computeError(data, truth, index=thisindex)
           IF n_elements(data) GT 116 THEN $
             real_big_err[i,j]=computeError(data, truth, $
                                      index=getBIGIndex(n_elements(data)))

;; print the results to the screen and a log file as we go
           print, strcompress(i), strcompress(j), strcompress(k), $
                  strcompress(n), strcompress(alpha), strcompress(Ks), $
                  strcompress(err[i,j,k]), strcompress(big_err[i,j,k]), $
                  strcompress(real_big_err[i,j,k]), $
                  strcompress(n_elements(data[2,*]))
           printf, un, strcompress(i), strcompress(j), strcompress(k), $
                   strcompress(n), strcompress(alpha),strcompress(Ks), $
                   strcompress(err[i,j,k]), strcompress(big_err[i,j,k]), $
                   strcompress(real_big_err[i,j,k]), $
                   strcompress(n_elements(data[2,*]))
;; write the full output from the current simulation to a file in outfiles
           openw, noun, /get, string('outfiles/', $
                                     strcompress(n, /remove_all), $
                                     strcompress(alpha, /remove_all), $
                                     strcompress(Ks, /remove_all), '.out')
           printf, noun, data
           close, noun  & free_lun, noun
           
;just how much did we get from that run anyway?
           help, data, truth
           
           k=k+1
        ENDFOR
        k=0
        j=j+1
ENDFOR
     j=0
     i=i+1
  ENDFOR
  close, un  & free_lun, un

;; write the full output to a binary file
  openw, un, /get, output
  writeu, un, err
  close, un &  free_lun, un

  openw, un, /get, output+'.big'
  writeu, un, big_err
  close, un &  free_lun, un
  openw, un, /get, output+'.huge'
  writeu, un, real_big_err
  close, un &  free_lun, un
  print, 'To Read in the output file use the following : '
  help, err
END

