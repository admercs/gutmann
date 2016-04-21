PRO fixclosure
  dirs=file_search('ihop?')

  dt=30 &  LH=23 &   H=24 &   Rn=20 &   G=25
  nsteps=48

  FOR i=0,n_elements(dirs)-1 DO BEGIN
     cd, current=olddir, dirs[i]
     measurefile=file_search('IHOPUDS*.txt')
     
     junk=load_cols(measurefile, data)
     closure=(data[LH,*]+data[H,*])/(data[Rn,*]+data[G,*])
     tmp=where(data[LH,*] GT 1000 OR data[LH,*] LT -500 OR $
               data[H,*] GT 1000 OR data[H,*] LT -500 OR $
               data[Rn,*] GT 1000 OR data[Rn,*] LT -500 OR $
               data[G,*] GT 1000 OR data[G,*] LT -500 OR $
               data[Rn,*] LT 100) ; look for mid day values only?
;               closure LT -5 OR closure GT 5)
     IF tmp[0] NE -1 THEN closure[tmp] = -999
     dailyclosure=dailyrainfall(closure, dt, /average, /midday, badval=-999)
     
     tmp=where(dailyclosure NE -999)
     IF tmp[0] NE -1 THEN BEGIN 
        print, "Closure for ; "+measurefile+" ="+strcompress(mean(dailyclosure[tmp]))
        IF abs(mean(dailyclosure[tmp])-1) GT 0.05 THEN BEGIN 
           print, '     FIXING : '+measurefile+" ...", format='($,A)'

;; for more human readable form see bottom of file for for loop version
;;
;;  this assumes that the number of elements in data is an exact multiple of n_dailyclosure
           adjustment=rebin( $
                      (1-transpose(dailyclosure))/2.0, $
                      2, n_elements(data[0,*]), /sample)
           tmp=where(adjustment[0,*] NE -999)
;           help, data, tmp, adjustment
           IF tmp[0] NE -1 THEN $
             data[LH:H,tmp]+=data[LH:H,tmp] * adjustment[*, tmp]
           
           openw, oun, /get, 'new'+measurefile
;           help, data
           printf, oun, data, $
                   format='(2(3I5,I8,I5),'+strcompress(n_elements(data[*,0])-10)+'F15.2)'
           close, oun
           free_lun, oun
           print, '  FIXED'
        ENDIF
     ENDIF

     cd, olddir
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
