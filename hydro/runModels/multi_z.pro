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
pro multi_z, outfile
  if n_elements(outfile) eq 0 then outfile='dT-v-Z'

  spawn, 'rm noah_offline.namelist'
  namelist=file_search('noah_*')
  elev=fltarr(n_elements(namelist))
  diff=fltarr(n_elements(namelist))
  for i=0, n_elements(namelist)-1 do begin
     height=(strsplit(namelist[i], '-', /extract))[1]
     z=float(height)

     print, 'Z= ', height
     print, 'Running Clay'
     spawn, string('cp ', namelist[i], ' noah_offline.namelist')
     spawn, 'cp IHOPstypclay IHOPstyp'
     spawn, '../../../bin/NOAH >out'
     spawn, string('mv fort.111 clay-', height)
     print, 'Running Sand'
     spawn, 'cp IHOPstypsand IHOPstyp'
     spawn, '../../../bin/NOAH >out'
     spawn, string('mv fort.111 sand-', height)     

     diff[i]=computeDiff('sand-'+height, 'clay-'+height)
     elev[i]=height

     print, height, diff[i]

  endfor
  plot, elev, diff, psym=2
  openw, oun, /get, outfile
  printf, oun, [transpose(elev), transpose(diff)]
  close, oun
  free_lun, oun

end
