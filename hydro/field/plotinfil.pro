;; plot infiltration from pressure transducers, uses hard coded locations to specify
;; different periods of pressure, not very useful overall
PRO plotinfil, fname, ranges=ranges, plot1=plot1

  junk=load_cols(fname, data)
  
  IF NOT keyword_set(ranges) THEN ranges=[[0,n_elements(data[0,*])-1]]
  IF keyword_set(plot1) THEN BEGIN 
     ranges=[[1,n_elements(data[0,*])-1], $
             [1,6000], $
             [2500,4400], $
             [700,2200], $
             [4500,5250], $
             [5300,5700], $
             [5780,5880]]
     titles=['Full Day', 'Experiment one', '21.5cm', '16.5cm', $
             '11.5cm','3.5cm', '1.5cm']
  ENDIF ELSE BEGIN 
     ranges=[[1,n_elements(data[0,*])-1], $
             [5900,9300], $
             [6200,7000], $
             [7040,7560], $
             [7570,7960], $
             [8020,8300], $
             [8300,9000]]
     titles=['Full Day', 'Experiment Two', '16.5cm', $
             '11.5cm','3.5cm', '1.5cm', '21.5cm']             
  ENDELSE 

  ;;  ranges*=(5/60.0)

  time=lindgen(n_elements(data[0,*]))*(5.0/60.0/60.0)

;  IF keyword_set(plotit) THEN !p.multi=[0,2,3]
  FOR i=0,n_elements(ranges[0,*])-1 DO BEGIN
     answer= linfit(time[ranges[0,i]:ranges[1,i]], $
                   data[6,ranges[0,i]:ranges[1,i]])
     plot, time[ranges[0,i]:ranges[1,i]], $
           data[6,ranges[0,i]:ranges[1,i]], /xs, $
           xtitle="Time (hours)", ytitle="Pressure (Volts)", $
           title=titles[i]+'  '+strcompress(answer[1])
;     plot, time[ranges[0,i]:ranges[1,i]], $
;           (data[6,ranges[0,i]:ranges[1,i]] - $
;            data[6,ranges[0,i]-1:ranges[1,i]-1]) / $
;           (5.0/60.0/60.0),$
;           /xs, xtitle="Time (hours)", ytitle="dV/dT (Volts/Hour)", $
;           title=titles[i]
;     IF i EQ 1 THEN !p.multi=[0,2,4]
  ENDFOR
  
  
END
