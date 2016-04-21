PRO fixclosure
  dirs=file_search('ihop?')

  dt=30 &  LH=23 &   H=24 &   Rn=20 &   G=25
  nsteps=48

  FOR i=0,n_elements(dirs)-1 DO BEGIN
     cd, current=olddir, dirs[i]
     measurefile=file_search('IHOPUDS*.txt')
     
     junk=load_cols(measurefile, data)
     closure=(data[LH,*]+data[H,*])/(data[Rn,*]+data[G,*])
     dailyclosure=dailyrainfall(closure, dt, /average)
     
     print, "Closure for ; "+measurefile+" ="+strcompress(mean(closure))
     IF abs(mean(closure)-1) GT 0.05 THEN BEGIN 
        print, '     FIXING : '+measurefile, format='($,A)'

;; for more human readable form see bottom of file for for loop version
;;
;;  this assumes that the number of elements in data is an exact multiple of n_dailyclosure
        adjustment=rebin( $
                   (1-transpose(dailyclosure))/2.0, $
                   2, n_elements(data[0,*]), /sample)

        data[[LH,H],*]+=data[[LH,H],*] * adjustment

        openw, oun, /get, 'new'+measurefile
        printf, oun, data, $
                format='(2(3I5,I8,I5),'+strcompress(n_elements(data[*,0])-10)+'F10.2)'
        close, oun
        free_lun, oun
        print, '  FIXED'
     ENDIF

     
  ENDFOR 
END

;; for loop version of adjustment, loops over days now do it in one big array
;        FOR j=0, n_elements(dailyclosure)-1 DO BEGIN
;           adjustment=(1-dailyclosure[j])/2.0
;
;           data[LH,j:j+nsteps-1]+=data[LH,j:j+nsteps-1] * adjustment
;           data[H,j:j+nsteps-1]+=data[H,j:j+nsteps-1] * adjustment
;
;           printf, oun, data[*,j:j+nsteps-1], $
;                   format='(2(3I5,I8,I5),'+strcompress(n_elements(data[*,0])-10)+'F10.2)'
;        ENDFOR
