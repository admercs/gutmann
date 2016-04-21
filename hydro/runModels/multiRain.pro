;; Loads the data from two noah runs (out put files specified by file1
;; and file2.)
;;
;; Returns the mean difference in Soil Skin Temperature
;; between the two runs at 11AM, noon, 1PM, and 2PM, over 5 days.  
;;
;; Specifically written to look at the delta T between a sandy soil
;; run and a clay soil run
;;
;; 10/17/2003
function computeDiff, file1, file2
;; read in the data files
  j=load_cols(file1, dat1)
  j=load_cols(file2, dat2)

  dayGain=48    ;; 48 timesteps/day
  hourOffset=22 ;; 11AM
  days=indgen(4)+3 ;; the days we want to look at 224, 225, 226, 227, 228
  index=days*daygain+houroffset ;; compute the index into the full array
  index=[index, index+2, index+4, index+6] ;; add 12noon 1PM, and 2PM
  index=[index, index+1]

;; 2 = skin temperature
;; 8 = top layer temperature
  diff=max(abs(dat1[2,index]-dat2[2,index]))
  return, diff
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; batch driver routine to run the NOAH model for varying heights of
;; temperature measurements.  Note that the data are the same for each
;; run but the model is told that the measurement elevation differs.  
;;
pro multiRain, outfile
  if n_elements(outfile) eq 0 then outfile='dT-v-Rain'


  namelist=file_search('IHOPUDS1-*')
  diff=fltarr(n_elements(namelist))
  rain=intarr(n_elements(namelist))
  for i=0, n_elements(namelist)-1 do begin

     rain[i]=fix((strsplit(namelist[i], '-', /extract))[1])
     IF rain[i] GT 0 THEN rain = rain+1
     rainstr=strcompress(rain[i], /remove_all)
     print, 'Rain =', rainstr

     print, 'Running Clay'
     spawn, string('cp ', namelist[i], ' IHOPUDS1')
     spawn, 'cp IHOPstypclay IHOPstyp'
     spawn, '../../../bin/NOAH >out'
     spawn, string('mv fort.111 clay-', rainstr)
     print, 'Running Sand'
     spawn, 'cp IHOPstypsand IHOPstyp'
     spawn, '../../../bin/NOAH >out'
     spawn, string('mv fort.111 sand-', rainstr)     

     diff[i]=computeDiff('sand-'+rainstr, 'clay-'+rainstr)

     print, diff[i]
     print, ''
  endfor

  plot, rain/2., diff, $
    psym=2, xr=[0, 35], $
    title='Rainfall vs Delta T', $
    xtitle='Rain (mm)', $
    ytitle='Delta T (K)'
;  oplot, Zo, diff

;; print the output to a file
  openw, oun, /get, outfile
  printf, oun, [transpose(rain), transpose(diff)]
  close, oun
  free_lun, oun

end
