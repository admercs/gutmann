pro idlGetWeather, location,fname
  if n_elements(location) eq 0 then location='KLBF'
  if n_elements(fname) eq 0 then fname='weather'+location
  

  openw, oun, /get, fname
  for i=1999,2002 do begin
    for j=1,12 do begin
      for k=1,31 do begin
        printf, oun, 'wget -q http://www.wunderground.com/history/airport/' + $
                location+'/'+strcompress(i,/remove_all)+'/'+ $
                strcompress(j,/remove_all)+'/'+strcompress(k,/remove_all)+ $
                '/DailyHistory.html'
      endfor
      printf, oun, 'echo "'+strcompress(j,/remove_all)+'/'+strcompress(i,/remove_all)+'"'
    endfor
  endfor

  close, oun
  free_lun, oun
  spawn, 'chmod +x '+fname

end
