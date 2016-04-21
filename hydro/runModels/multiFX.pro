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
  days=indgen(3)+4;224 ;; the days we want to look at 224, 225, 226, 227, 228
  index=days*daygain+houroffset ;; compute the index into the full array
  index=[index, index+2, index+4, index+6] ;; add 12noon 1PM, and 2PM

;; 2 = skin temperature
;; 8 = top layer temperature
  diff=max(abs(dat1[2,index]-dat2[2,index]))
  return, diff
end

;; write the GENPARM.TBL file for the current value of FX exponent
pro writeGENPARM, fx
  header = 14
  line=''

  openr, un, /get, 'GENPARM.master'
  openw, oun, /get, 'GENPARM.TBL'

; copy the first 14 lines from the master to the new file
  for i=0, header do begin
     readf, un, line
     printf, oun, line
  endfor

; skip the FX line from the master and write in the current value instead
  readf, un, line
  printf, oun, strcompress(fx, /remove_all)
  
; copy the rest of the file from the master to the new GENPARM.TBL
  while not eof(un) do begin
     readf, un, line
     printf, oun, line
  endwhile

; cleanup
  close, oun, un
  free_lun, oun, un

end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; batch driver routine to run the NOAH model for varying heights of
;; temperature measurements.  Note that the data are the same for each
;; run but the model is told that the measurement elevation differs.  
;;
pro multiFX, outfile
  if n_elements(outfile) eq 0 then outfile='dT-v-FXclay'

  FX = indgen(99)/25. + 0.01

  diff=fltarr(n_elements(FX))
  for i=0, n_elements(FX)-1 do begin

     current=string(FX[i], FORMAT='(F5.3)')
     print, 'FX= ', FX[i]
     print, 'Running Clay'
     writeGENPARM, FX[i]
     spawn, 'cp IHOPstypclay IHOPstyp'
     spawn, '../../../bin/NOAH >out'
     spawn, string('mv fort.111 clay-', current)
     print, 'Running Sand'

     spawn, 'cp GENPARM.master GENPARM.TBL'
     spawn, 'cp IHOPstypsand IHOPstyp'
     spawn, '../../../bin/NOAH >out'
     spawn, string('mv fort.111 sand-', current)     

     diff[i]=computeDiff('sand-'+current, 'clay-'+current)

     print, diff[i]

  endfor

  plot, FX, diff, $
;    /xlog, psym=2, xr=[0.0001, 10], $
    title='FX exponent  vs Delta T', $
    xtitle='Evaporation Exponent', $
    ytitle='Delta T (K)'
  oplot, FX, diff

;; print the output to a file
  openw, oun, /get, outfile
  printf, oun, [transpose(FX), transpose(diff)]
  close, oun
  free_lun, oun

end
