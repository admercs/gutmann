;; FUNCTION fitSine
;;
;;  Opens all files matching *.txt in the current directory
;;    for each file fits a sine curve to the data
;;    Sine curve is currently forced to have a period of one year (12)
;;    
;;  input data must be two column space or tab delimited text files
;;  
;;  output file will have a one line header, then be column formated text
;;    FileName amplitude y-offset phase_Shift 2pi/period r^2 rmse
;;
;; also useful :
;;
;;   FUNCTION fitFile
;;
;;  fits a sine curve to a single tab or space delimited text file


FUNCTION findError, x, y, period, shift, offset, amp
;; compute the values for the current sine curve at all specified X locations
  yprime=offset+amp*sin((x+shift)*period)

;; compte the Root Mean Square Error (RMSE)
  error=sqrt(total((yprime-y)^2)/n_elements(x))

  return, error
END



;; fit a sine curve to the file fname
;;  returns essential parameters for the best fit sine curve
FUNCTION FitFile, fname
;; read in the data
  junk= load_cols(fname, data)

;; change variable names
  Xvals=data[0,*]
  Yvals=data[1,*]

;; this is the number of steps to take through each parameter
  n=100.

;; force the period to be one year
  period=(2.0*!pi)/12

;; set up the min, max (and range) of mean offset value
  minOffset=min(Yvals)
  maxOffset=max(Yvals)
  rangeOffset=maxOffset-minOffset
  
;; set up the min, max (and range) of amplitude value
  minAmplitude=abs(maxOffset-minOffset)/10.0
  maxAmplitude=abs(maxOffset-minOffset)/2.0
  rangeAmplitude=maxAmplitude-minAmplitude

;; set up the min, max (and range) of phase shift value
  minShift=0.0
  maxShift=12.0
  rangeShift=maxShift-minShift

;; some HUGE value
  minError=99999.0
;; calculate the total Sum Square Error in the data set for use in
;;   calculating R^2
  ave=mean(Yvals)
  totalError=total((Yvals-ave)^2)

;; loop over all reasonable offset, amplitude and phase shift values
  FOR offset=minOffset, maxOffset, rangeOffset/n DO BEGIN
     FOR amp=minAmplitude, maxAmplitude, rangeAmplitude/n DO BEGIN
        FOR shift=minShift, maxShift, rangeShift/100 DO BEGIN

;; calculate the RMS error between the current sine curve and the data
           error=FindError(Xvals, Yvals, period, shift, offset, amp)
;; If this is the minimum error we have found so far then save this value
           IF error LT minError THEN BEGIN
              minError=error
              output={amp:amp, offset:offset, phase:shift, $
                      period:period,rms:error, r2:0.0}
           ENDIF
        endFOR
     ENDFOR
  ENDFOR

;; calculate R^2
  yprime=output.offset+output.amp*sin((Xvals+output.phase)*output.period)
  modelError=total((yprime-output.offset)^2)

  output.r2=modelError/totalError

;; make a pretty plot of the best fit
  raw=indgen(1000)/(999.0)*max(Xvals)
  plot, raw, output.offset + output.amp*sin((raw+output.phase)*output.period), $
        title=string(fname,'  R^2=',strcompress(output.r2), $
              '  RMSE=',strcompress(output.rms), format='(2A,F5.2,A,F6.2)'), $
        ytitle="Isotopic Value", $
        xtitle="Month of the Year", $
        yr=[min(Yvals),max(Yvals)]
  oplot, Xvals, Yvals, psym=1

  return, output
END


;; fit a sine curve to a list of data file and write the output for
;;  each file on it's own line in a prespecified output file
PRO fitSine, outputFilename
;  openw, oun, outputFilename, /get

;; we are also going to make nice plots along the way
  old=setupplot(filename=outputfilename+'.ps')
  !p.multi=[0,2,3]

;; find all of the files we are going to fit
  filelist=file_search("*.txt")
; how many files?
  nfiles=n_elements(filelist)
;; print a header to both the text file and the screen output
;  printf, oun, "FileName Amplitude Signal_Offset Phase_Shift Period_Gain R^2 RMS_error"
  print, "FileName Amplitude Signal_Offset Phase_Shift Period_Gain R^2 RMS_error"

;; loop through all files fiting a sine curve and outputing the data
  FOR i=0, nfiles-1 DO BEGIN
;; fit the sine curve
     params=FitFile(filelist[i])
;; output the fit
;     printf, oun, filelist[i], strcompress(params.amp), $
;             strcompress(params.offset), $
;             strcompress(params.phase), $
;             strcompress(params.period), $
;             strcompress(params.r2), $
;             strcompress(params.rms), format='(A,4F8.2,F6.2,F8.4)'
;; print the fit to the screen too so we can watch
     print, filelist[i], strcompress(params.amp), $
            strcompress(params.offset), $
            strcompress(params.phase), $
            strcompress(params.period), $
            strcompress(params.r2), $
            strcompress(params.rms), format='(A,4F8.2,F6.2,F8.4)'
  endFOR
;; clean up
;  close, oun
;  free_lun, oun
  resetplot, old
end
             
     
