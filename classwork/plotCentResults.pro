PRO plot_Cent_Data, files, column, _extra=e
  junk=readCentCSV(files[0])
  data=junk.data

  colorindex=indgen(10)*(63/9.0)+8  ;smooth reds
  colorindex=[colorindex[0:8],2,3,colorindex[9]] ;; add in green and blue for clay and silt

  basecolor=0
  plot, data[0,1:*], data[column, 1:*], _extra=e
  oplot, data[0,1:*], data[column, 1:*], color=colorindex[0]
  FOR i=1,n_elements(files)-1 DO begin
     junk=readCentCSV(files[i])
     data=junk.data
;     IF i GT 7 THEN col=i-7+197 ELSE col=i
     oplot, data[0,1:*], data[column, 1:*], color=colorindex[i]
  ENDFOR

END


PRO plotCentResults, ps=ps
  IF keyword_set(ps) THEN BEGIN
     old=setupplot()
  ENDIF
  !p.multi=[0,1,2]

  water=file_search('*.wt.csv')
  nitro=file_search('*.nps.csv')
  cropC=file_search('*.cropC.csv')
  soilC=file_search('*.soilC.csv')

  plot_Cent_Data, water, 3, title="Top Soil Moisture", yr=[0,10], $
                  xtitle="Time (years)", ytitle="Soil Moisture (mm)"
  plot_Cent_Data, water, 13, title="Growth Soil Moisture", $
                  xtitle="Time (years)", ytitle="Soil Moisture (mm)"
;  plot_Cent_Data, water, 14, title="Survival Soil Moisture"
;  plot_Cent_Data, water, 17, title="Evaporation"
;  plot_Cent_Data, nitro, 25, title="Above ground live N"
  plot_Cent_Data, nitro, 28, title="Mineral N in layer 1 (pre-uptake)", $
                  xtitle="Time (years)", ytitle="Mineral Nitrogen (g/m!U2!N)"
;  plot_Cent_Data, nitro, 31, title="Below ground live N"
;  plot_Cent_Data, nitro, 1, title="Limiting nutrient", yr=[0,4]
;  plot_Cent_Data, nitro, 121, title="Mineral N in layer 1"
;  plot_Cent_Data, nitro, 122, title="Mineral N in layer 2"
;  plot_Cent_Data, nitro, 123, title="Mineral N in layer 3"
;  plot_Cent_Data, nitro, 124, title="Mineral N in layer 4"
;  plot_Cent_Data, cropC, 37, title="Standing dead C"
  plot_Cent_Data, cropC, 21, title="Carbon production", $
                  xtitle="Time (years)", ytitle="Carbon Production (g/m!U2!N/month)"
;  plot_Cent_Data, cropC, 8, title="Above ground live C"
;  plot_Cent_Data, cropC, 15, title="Below ground live C"
  plot_Cent_Data, soilC, 36, title="C in active SOM pool", $
                  xtitle="Time (years)", ytitle="Carbon in Active SOM Pool (g/m!U2!N)"
;  plot_Cent_Data, soilC, 41, title="C in slow SOM pool"
;  plot_Cent_Data, soilC, 44, title="C in passive SOM pool"
;  plot_Cent_Data, soilC, 53, title="Total C in soil profile"

  IF keyword_set(ps) THEN BEGIN
     resetplot, old
  ENDIF

END
