;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Makes the input data for the Disc SHP program.
;;
;;  Takes the output data file from the tension disc infiltrometers, and
;;  an info file that tells it which data in the data file are useful.
;;  Info can contain a header, then it must contain column formated data
;;    Column1 = Column to read data from in Data file
;;    Column2 = Site number (ignored)
;;    Column3 = tension number (also ignored for now)
;;    Column4 = Start position in data array for a batch of "good" data
;;    Column5 = End position in data array for "good" data
;;    Column6 = top of water in bubbleing tube for this interval
;;    Column7 = bottom of air entry tube for this interval
;;    Column8 = match or not (1 if we should match the start of the current
;;              interval with the end of the last interval (time and pressure)
;;              0 if we should not do anything to match the two up.)
;;              IF NEGATIVE then this row is flagged not to be used
;;
;;  Last line of info file should contain the same number of columns
;;    Column1 = Final moisture content
;;    Column2 = initial moisture content
;;    Column3 = Pressure transducer offset
;;    Column4 = Pressure transducer gain
;;    Column5 = Infiltrometer pressure offset
;;  
;;  Data file must be converted from comma delimited to space delimited first.
;;  (commatospace, oldfile, newfile)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRO make_disc_data, info_fname, data_fname, out_fname, $
                    reverse=reverse, plot=plot
  junk= load_cols(info_fname, info)
  junk= load_cols(data_fname, data)

  dataColumn=info[0,*]
  startCol=3
  stopCol =4
  matchCol=7
  IF keyword_set(reverse) $
    OR mean(data[dataColumn[0],info[startCol,0]:info[stopCol,0]]) GT 0 $
  THEN data[dataColumn[0],*]*=-1

  ;; remove values flagged not to be used
  info=info[*,where(info[matchCol,*] GE 0)]  

  ;; make time in seconds
  hrMin=data[3,*]
  time=long(fix(hrMin/100)*3600.0+(hrmin MOD 100)*60.0 + data[4,*])
  time-=time[info[startCol,0]]  
  ;; set to time to be seconds since experiment begins
  
  ;; read the first batch of data so we can start at the second batch and
  ;; continuously concatenate on to the current data
  output=reform(data[dataColumn[0],info[startCol, 0]:info[stopCol,0]])
  outtime=time[info[startCol,0]:info[stopCol,0]]
  tensionTime=outtime[0]
  outtensions=info[6,0]-info[5,0]


  FOR i=1, n_elements(info[0,*])-2 DO BEGIN
;; if we need to match up the end of the last section with the start of this section
     IF info[matchCol,i] EQ 1 THEN BEGIN
        ;; match output levels
        data[dataColumn[i],*]-= $
          data[dataColumn[i],info[startCol,i]]-output[n_elements(output)-1]
        ;; match times
        time-=time[info[startCol,i]]-outtime[n_elements(output)-1]
     ENDIF

     curOutput=reform(data[dataColumn[i],info[startCol, i]:info[stopCol,i]])
     curOuttime=time[info[startCol, i]:info[stopCol,i]]
     
     output=[output,curOutput]
     outTime=[outTime,curOutTime]
     outtensions=[outtensions, info[6,i]-info[5,i]]
     tensionTime=[tensionTime,curOutTime[0]]
  ENDFOR


  output*=info[3,n_elements(info[0,*])-1]
;  output+=info[2,n_elements(info[0,*])-1]  ;we don't really want to offset this?
  outtensions-=(10*info[4,n_elements(info[0,*])-1])
  outtensions*=(-1)
  rsfactor=5
  outTime=rebin(outTime[0:fix(n_elements(outTime)/5)*5-1],n_elements(outTime)/5)
  output-=output[0]
  output=rebin(output[0:fix(n_elements(output)/5)*5-1],n_elements(output)/5)*1.9635
  print, n_elements(output), n_elements(info[0,*])-1

;  stop
  write_disc_in, outTime, output, tensionTime, outtensions/10, $
                 info, info_fname, out_fname
  IF keyword_set(plot) THEN $
     plot, outTime, output, psym=1

END



PRO write_disc_in, outTime, output, tensionTime, outtensions, $
                   info, description, out_fname
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Output data to output file for pasting into Disc.IN file, eventually we
;;   should write the entire Disc.IN file.  
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  openw, oun, out_fname, /get

  printf, oun, "Tension Disc Infiltrometer -- "+description
  printf, oun, "      NOBB       MIT     NofBC"
  printf, oun, string(n_elements(output), format='(I10)'), '        50', $
          string(n_elements(outtensions), format='(I10)')
  printf, oun, "LUnit  TUnit  (indicated units are obligatory for all input data) ----"
  printf, oun, "cm"
  printf, oun, "sec"
  printf, oun, "     tInit    dtInit     dtMin"
  printf, oun, "         0         1      0.01"
  printf, oun, "      Mesh    ThetaI    ThetaF     DiskD"
  printf, oun, "         1", $
          string(info[1,n_elements(info[0,*])-1]/100.0, format='(F10.3)'), $
          string(info[0,n_elements(info[0,*])-1]/100.0, format='(F10.3)'), $
          "        20"
  printf, oun, "       thr        ths       Alfa          n         Ks          l"
  printf, oun, "      0.01       0.44       0.07        1.9      0.003        0.5 "
  printf, oun, "         0          1          1          1          1          0 "
  printf, oun, "         0       0.27          0       1.01     1e-006          0 "
  printf, oun, "         0       0.75          0       50.0       50.0          0 "
  printf, oun, "      Time     hBound"
  FOR i=0, n_elements(outtensions)-2 DO BEGIN
     printf, oun, string(tensionTime[i+1], format='(I10)'), $
             strcompress(string(outtensions[i], format='(F10.2)'))
  ENDFOR
  printf, oun, string(outTime[n_elements(outTime)-1], format='(I10)'), $
          strcompress(string(outtensions[n_elements(outtensions)-1], format='(F10.2)'))
  printf, oun, '      Time     Cum.Inf.'
  FOR i=0, n_elements(outTime)-1 DO BEGIN
     printf, oun, string(outTime[i], format='(I10)'), $
             strcompress(string(output[i], format='(F10.2)'))
  ENDFOR
  printf, oun, '*** End of the Input File ********************************************'
  close, oun
  free_lun, oun
;; convert unix to dos line endings for DISC
  spawn, 'unixdos '+out_fname+' '+out_fname+'.dos'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This is the old way of printing this out so it will be tab delimited and
;; can be pasted into the DISC programs GUI.  This seems to crash DISC so now
;; we format the output as above so it can be used directly as Disc.IN
;; file (convert unix to dos line endings)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  tabs=replicate(string(9B), n_elements(outTime))
;  printf, oun, [strcompress(transpose(outTime), /remove_all), $
;                transpose(tabs), $
;                strcompress(transpose(output), /remove_all)]
;  tabs=replicate(string(9B), n_elements(outtensions))
;  printf, oun, [strcompress(transpose(tensionTime), /remove_all), $
;                transpose(tabs), $
;                strcompress(transpose(outtensions), /remove_all)]  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
END

