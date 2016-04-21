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
  days=indgen(5)+4;224 ;; the days we want to look at 224, 225, 226, 227, 228
  index=days*daygain+houroffset ;; compute the index into the full array
  index=[index, index+2, index+4, index+6] ;; add 12noon 1PM, and 2PM

;; 2 = skin temperature
;; 8 = top layer temperature
  diff=mean(dat1[0,index]-dat2[0,index])
  return, diff
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; batch driver routine to run the NOAH model for varying heights of
;; temperature measurements.  Note that the data are the same for each
;; run but the model is told that the measurement elevation differs.  
;;
pro multi_z2, outunit, zo
  if n_elements(outunit) eq 0 then openw, outunit, 'outfile', /append, /get

  spawn, 'rm noah_offline.namelist'
  namelist=file_search('noah_*')
  elev=fltarr(n_elements(namelist))
  diff=fltarr(n_elements(namelist))

  zlev = strcompress(zo, /remove_all)

  for i=0, n_elements(namelist)-1 do begin
     height=(strsplit(namelist[i], '-', /extract))[1]
     z=float(height)

     print, 'Z= ', height
     print, 'Running Clay'
     spawn, string('cp ', namelist[i], ' noah_offline.namelist')
     spawn, 'cp IHOPstypclay IHOPstyp'
     spawn, '../bin/NOAHopt >out'
     spawn, string('mv fort.111 clay-', height, '-', zlev)
     print, 'Running Sand'
     spawn, 'cp IHOPstypsand IHOPstyp'
     spawn, '../bin/NOAHopt >out'
     spawn, string('mv fort.111 sand-', height, '-', zlev)

     diff[i]=computeDiff('sand-'+height+'-'+zlev, 'clay-'+height+'-'+zlev)
     elev[i]=z

     print, zo, height, diff[i]

     printf, outunit, [zo, z, diff[i]]
  endfor
  plot, elev, diff, psym=2
;  openw, oun, /get, outfile
;  close, oun
;  free_lun, oun

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; batch driver routine to run the NOAH model for varying heights of
;; temperature measurements.  Note that the data are the same for each
;; run but the model is told that the measurement elevation differs.  
;;
pro multi_Both, outfile
  if n_elements(outfile) eq 0 then outfile='dT-v-rough'

  Zo=[0.001, 0.003, 0.007, 0.01, 0.03, 0.07, 0.1, 0.3, 0.7, 1, 3]
  openw, oun, /get, outfile

  namelist=file_search('IHOPluse??')

  for i=0, n_elements(namelist)-1 do begin

     rough=string(Zo[i], FORMAT='(F5.3)')
     print, 'Roughness= ', Zo[i]
;     print, 'Running Clay'
     spawn, string('cp ', namelist[i], ' IHOPluse')
;     spawn, 'cp IHOPstypclay IHOPstyp'
;     spawn, '../bin/NOAH >out'
;     spawn, string('mv fort.111 clay-', rough)
;     print, 'Running Sand'
;     spawn, 'cp IHOPstypsand IHOPstyp'
;     spawn, '../bin/NOAH >out'
;     spawn, string('mv fort.111 sand-', rough)     

;     diff[i]=computeDiff('sand-'+rough, 'clay-'+rough)

     multi_z2, oun, Zo[i]
;     print, diff[i]

  endfor

;  plot, Zo, diff
;    /xlog, psym=2, xr=[0.0001, 10], $
;    title='Roughness vs Delta T', $
;    xtitle='Roughness (log)', $
;    ytitle='Delta T (K)'
;  oplot, Zo, diff

;; print the output to a file
  close, oun
  free_lun, oun

end
