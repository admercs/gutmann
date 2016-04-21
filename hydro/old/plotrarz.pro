;; plots the effects of rain, albedo, roughness, and z (measurement elevation)
PRO processSubDIR, pName, nthVar=nthVar, noColor=noColor
  IF NOT keyword_set(nthVar) THEN nthVar=4

  filelist=file_search("*", count=nfiles, /test_directory)
  CASE nthVar OF 
     1 : SHP="Residual Water Content"
     2 : SHP="Saturaded Water Content"
     3 : BEGIN
        xtitle="True Saturated Conductivity Value"
        ytitle="Saturated Conductivity Range (log)"
        xlog=1
        xr=[3E-7,1E-3]
        yr=[0,3]
        legendx=[4E-7,9E-7]
        legendy=[2.83,2.83]
        labelx=1E-6
        labely=2.78
        maxval=alog10(5E-4)
        minval=alog10(5E-7)
        xvals=10.0^((indgen(51)/(50.))*(maxval-minval) + minval)
     END
     4 : BEGIN
        ytitle="Beta Range"
        xtitle="True Beta Value"
        xr=[0,15]
        yr=[0,15]
        legendx=[0.5,1.5]
        legendy=[14.5,14.5]
        labelx=2
        labely=14.35
        maxval=15.
        minval=1.
        xvals=(indgen(51)/(50.))*(maxval-minval) + minval 
     END 
  ENDCASE 

  gain=63./nfiles
  FOR i=0,nfiles-1 DO BEGIN
     IF NOT keyword_set(noColor) THEN color=gain*i+7
     pVal=strmid(filelist[i], 0, strlen(filelist[i])-1)

     cd, filelist[i], current=old
     data=read1Var(srch='out.*', nthVar=nthVar)
     acc=SHP_accuracy(data.data, 1)
;     IF nthVar EQ 3 THEN acc=10.0^(((acc[1,*]-acc[0,*])/50.)*(maxval-minval)) $
;     ELSE acc=((acc[1,*]-acc[0,*])/50.)*(maxval-minval)
     acc=((acc[1,*]-acc[0,*])/50.)*(maxval-minval)

     IF i EQ 0 THEN begin
     plot, xvals, acc, title=pName, yr=yr, xr=xr, $
           xtitle=xtitle, ytitle=ytitle, color=color, $
           xlog=xlog, ylog=ylog, /xs
     ENDIF ELSE $
       oplot, xvals, acc, color=color

;; make the legend
     CASE nthVar OF 
        1: yoff=i/2.
        2: yoff=i/2.
        3: yoff=i/8.
        4: yoff=i/2.
     ENDCASE 

     oplot, legendx, legendy-yoff, color=color
     oldSize=!p.charsize
     !p.charsize=0.6
     xyouts, labelx, labely-yoff, pVal
     !p.charsize=oldSize

     print, pVal
     cd, old
  ENDFOR
  
END


FUNCTION getFilenames, inputFile
  openr, un, /get, inputFile
  line=''
  readf, un, line
  output=line
  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     output=[output,line]
  ENDWHILE
  close, un  & free_lun, un
  return, output
END 
  
PRO plotrarz, filelist, nthVar=nthVar, noColor=noColor
  IF n_elements(filelist) EQ 0 THEN filelist="inputlist"
  files=getFilenames(filelist)
  FOR i=0, n_elements(files)-1 DO BEGIN
     cd, files[i], current=old
     print, files[i]
     processSubDIR, files[i], nthVar=nthVar, noColor=noColor
     cd, old
  ENDFOR
END

