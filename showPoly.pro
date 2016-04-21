PRO showPoly, polyList,arcs,i, xr,yr
  n_arcs=polyList.info[0,i]
  line=''
  firstPlot=0

  IF n_elements(xr) EQ 0 THEN BEGIN
     xr=[polyList.info[1,i],polyList.info[3,i]]
     yr=[polyList.info[2,i],polyList.info[4,i]]
  ENDIF      
  
  
  FOR j=0,n_arcs-1 DO BEGIN
     curArc=abs(polyList.arcs[j*3,i])-1
     
     ;; if curArc == -1 then we polyList.arcs=0 and is invalid?
     print, polyList.arcs[j*3,i]
     IF curArc NE -1 THEN BEGIN 
        curPoints=arcs[curArc].info[6]

        IF firstPlot EQ 0 THEN BEGIN 
           plot, arcs[curArc].points[0,0:curPoints-1], $
                 arcs[curArc].points[1,0:curPoints-1], $
                 xr=xr,yr=yr, /xs,/ys
           firstPlot=1
        ENDIF ELSE BEGIN 
           oplot, arcs[curArc].points[0,0:curPoints-1], $
                 arcs[curArc].points[1,0:curPoints-1]
        ENDELSE            
        plots, arcs[curArc].points[0,0], $
               arcs[curArc].points[1,0], psym=2
        
        read, line
        
     endIF 
  ENDFOR
END
