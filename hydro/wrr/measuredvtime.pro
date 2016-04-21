FUNCTION getmidday, data, startday

  morning=24
  afternoon=33
  vals=fltarr(6)
  endday=startday+5

  FOR day=startday, endday DO BEGIN
     vals[day-startday]=mean(data[(day*48l+morning):(day*48l+afternoon)])
  ENDFOR
  return, vals
END

pro measuredvtime, outfname
  
  fluxcol=23
  Rncol=20
  ;days=[30,30,30,30,30,30,30,30,30,260,260]
  days=[30, 30, 37, 38, 38, 30, 14, 46, 46,261,261]-11
  
  if n_elements(outfname) eq 0 then outfname ="measuredvtime.ps"
  old=setupplot(filename=outfname)
  !p.multi=[0,1,2]
  
  dirs=file_search("ihop?")
  for i=0, n_elements(dirs)-1 do begin
     cd, dirs[i], current=olddir
     file=file_search('IHOPUDS*.txt')
     junk=load_cols(file, data)
     midday_flux=getmidday(data[fluxcol,*], days[i])
     midday_Rn=getmidday(data[Rncol,*], days[i])
     
     if n_elements(allflux) eq 0 then allflux=midday_flux else $
       allflux=[[allflux], [midday_flux]]
     if n_elements(allRn) eq 0 then allRn=midday_Rn else $
       allRn=[[allRn], [midday_Rn]]
     
     cd, olddir
  endfor
  
  plot, allflux[*,1], $
    title="Measured LH all stations", $
    xtitle="Day after storm", $
    ytitle="Latent Heat Flux (W/m!U2!N)", $
    yr=[0,500]
  
  for i=1, n_elements(dirs)-1 do oplot, allflux[*,i]
  
  allflux/=allRn                ; convert LH to EF
  plot, allflux[*,1], $
    title="Measured EF all stations", $
    xtitle="Day after storm", $
    ytitle="Evaporative Fraction", $
    yr=[min(allflux),max(allflux)]
  
  for i=1, n_elements(dirs)-1 do oplot, allflux[*,i]
  
  resetplot, old
end
