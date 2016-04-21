PRO writeSOILPARM, tmp, index, val
  default=tmp
  default.data[index]=val
  openw, oun, /get, 'SOILPARM.TBL'
  printf, oun, 'Soil Parameters'
  printf, oun, 'STAS            m^3/m^3             m^3/m^3  m^3/m^3  1/m      m/s       1/s        m^3/m^3'
  printf, oun, '1,1   VGN      DRYSMC      F11     MAXSMC   REFSMC   VGALPHA  SATDK     SATDW      WLTSMC  QTZ'
  printf, oun, strjoin(default.data, ',')+', '+default.name
  close, oun
  free_lun, oun
END


PRO run_effect, default, index=index, minval=minval, maxval=maxval, levels=levels, log=log

;; just incase
  IF file_test('out.hrldas') THEN spawn, 'rm out.hrldas'
  minval=float(minval)
  maxval=float(maxval)
  levels=float(levels)
;; end just incase

  IF keyword_set(log) THEN BEGIN 
     minval=alog10(minval)
     maxval=alog10(maxval)
  ENDIF
  step=(maxval-minval)/levels

  FOR curval=minval, maxval, step DO BEGIN
     IF keyword_set(log) THEN passval=10.0^curval ELSE passval=curval
     writeSOILPARM, default, index, passval
     spawn, './noah &>/dev/null'
     spawn, 'mv out.hrldas '+strcompress(index)+'_'+strcompress(curval,/remove_all)+'.out'
  ENDFOR

END


PRO run_shp_effects

  defaultSHP = {data:[1,  1.45,    0.039,    -0.569,   0.387,   0.383,   2.69,    4.40E-6, $
                      0.805E-5,   0.039,  0.60], name:'''SANDY LOAM'''}
  
  

  ;; look at n
  run_effect, defaultSHP, index=1, minval=1.1, maxval=6, levels=20

  ;; look at Ks
  run_effect, defaultSHP, index=7, minval=1.0E-7, maxval=1.0E-3, levels=20, /log

  ;; look at alpha
  run_effect, defaultSHP, index=6, minval=0.1, maxval=10, levels=20


END

