PRO IHOP2noah, IHOPfile, noahFile, interp=interp
  IF n_elements(noahFile) EQ 0 THEN noahFile="IHOPUDS1"
  junk=load_cols(IHOPfile, data)
  openw, oun, /get, noahFile

  printf, oun, "Date"
  printf, oun, "GMT				1	1	1	1	1	1	1	1	1	1"
  printf, oun, "YEAR	month	newday	newtime	P	windspd	T	MR	Rsw.in	Rlw.in	rain	LAI	NDVI	Fg"
  printf, oun, "yyyy	mm			mb-true	m/s	(degC)	(g/kg)	(W/m^2)	(W/m^2)	(mm)"

  index=[0,1,2,3,13,15,12,14,10,11,18]
  dummycol=transpose(intarr(n_elements(data[0,*])))
  output=[data[index,*], dummycol+3, dummycol+0.328, dummycol+0.5]
  output[3,*]+=1500
  printf, oun, output, format='(I4,I4,I4,I8,7F10.3, I4,F6.3,F5.2)'
  printf, oun, output, format='(I4,I4,I4,I8,7F10.3, I4,F6.3,F5.2)'
  printf, oun, output, format='(I4,I4,I4,I8,7F10.3, I4,F6.3,F5.2)'
  printf, oun, output, format='(I4,I4,I4,I8,7F10.3, I4,F6.3,F5.2)'
  printf, oun, output, format='(I4,I4,I4,I8,7F10.3, I4,F6.3,F5.2)'
  printf, oun, output, format='(I4,I4,I4,I8,7F10.3, I4,F6.3,F5.2)'
  printf, oun, output, format='(I4,I4,I4,I8,7F10.3, I4,F6.3,F5.2)'
  printf, oun, output, format='(I4,I4,I4,I8,7F10.3, I4,F6.3,F5.2)'
  printf, oun, output, format='(I4,I4,I4,I8,7F10.3, I4,F6.3,F5.2)'
  printf, oun, output, format='(I4,I4,I4,I8,7F10.3, I4,F6.3,F5.2)'
  close, oun
  free_lun, oun

  IF keyword_set(interp) THEN interpWeather, noahFile, 10, noahFile+".vg"
end
