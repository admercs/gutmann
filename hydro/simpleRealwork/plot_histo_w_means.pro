FUNCTION getSHPs, soilsindex, databasefile
  junk=load_cols(databasefile, database)
  dataindex=lonarr(n_elements(soilsindex))
  FOR i=0, n_elements(soilsindex)-1 DO BEGIN
    dataindex[i]=where(database[0,*] EQ soilsindex[i])
    IF dataindex[i] EQ -1 THEN BEGIN        
       print, "ERROR : missing soil ",soilsindex[i], i
       retall
;       dataindex[i]=0
    ENDIF

 ENDFOR

;;database columns =
;;       0          1       2       3       4    5    6     7    8        9
;;  soil number, unused, unused, unused, unused, n, alpha, ks, theta_s, theta_r
  return, database[5:9, dataindex]
end


FUNCTION getClasses, inputtextureclass, classfile
  index=[1,6,7,4,2]; columns in SOILPARM.TBL corresponding to n, alpha, ks, t_s, t_r
  textureclass=inputtextureclass
  oversilt=where(textureclass GT 3)
  IF oversilt[0] NE -1 THEN textureclass[oversilt]++

  ;; classfile should be a standard SOILPARM.TBL file
  classdata= load_n_cols(8, classfile, separator=',', header=3)
  classdata=classdata[index,*]
  classdata=classdata[*,textureclass]
  return, classdata
END 

PRO plot_histo_w_means, bestsoils, varcol=varcol, _extra=e
  
  IF NOT keyword_set(varcol) THEN varcol=0
  database="database/vgHTHK"
  fulldatabase="database/newRosetta.txt"
  defaults="database/SOILPARM.TBL"
  IF n_elements(bestsoils) EQ 0 THEN bestsoils="bestsoils"

  junk=load_cols(bestsoils, best)
  txtcls=transpose(indgen(10))
  
  bestSHPs=getSHPs(best[0,*], database)
  classes=getClasses(txtcls, defaults)
  
  oversilt=where(best[1,*] GT 3)
  IF oversilt[0] NE -1 THEN best[1,oversilt]--

  classAve=[txtcls,classes[varcol,*]]
  true=[best[1,*],bestSHPs[varcol,*]]
  boxn, fulldatabase, classAve=classAve, true=true, /histo, _extra=e, $
        varCol=([11,10,7,9,8])[varcol]
  
END
