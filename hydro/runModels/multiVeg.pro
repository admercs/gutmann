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
;; batch driver routine to run the NOAH model for varying veg covers
;; Note that the data are the same for each
;; run but the model is told that the measurement elevation differs.  
;;
pro multiVeg, outfile
  if n_elements(outfile) eq 0 then outfile='dT-v-veg'

  veg=indgen(10)/10.0

  luse=file_search('IHOPluse??')
  diff=fltarr(n_elements(luse))
  for i=0, n_elements(luse)-1 do begin

     veg=string(veg[i], FORMAT='(F5.3)')
     print, 'Veg Cover= ', veg[i]
     print, 'Running Clay'
     spawn, string('cp ', luse[i], ' IHOPluse')
     spawn, 'cp IHOPstypclay IHOPstyp'
     spawn, '../../../bin/NOAH >out'
     spawn, string('mv fort.111 clay-', veg)
     print, 'Running Sand'
     spawn, 'cp IHOPstypsand IHOPstyp'
     spawn, '../../../bin/NOAH >out'
     spawn, string('mv fort.111 sand-', veg)     

     diff[i]=computeDiff('sand-'+veg, 'clay-'+veg)

     print, diff[i]

  endfor

  plot, veg, diff, $
    psym=2, xr=[0,1], $
    title='Vegetation vs Delta T', $
    xtitle='Vegetation Cover', $
    ytitle='Delta T (K)'
  oplot, veg, diff

;; print the output to a file
  openw, oun, /get, outfile
  printf, oun, [transpose(veg), transpose(diff)]
  close, oun
  free_lun, oun

end
