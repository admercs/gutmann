pro batchGetWeather, stationlist
  openr, un, /get, stationlist

  line=' '

  while not eof(un) do begin
    readf, un, line
    spawn, 'mkdir '+line
    cd, line
    idlGetWeather, line
    cd, '../'
  endwhile

  close, un
  free_lun, un
end

pro runIt, stationlist
  openr, un, /get, stationlist

  line=' '

  while not eof(un) do begin
    readf, un, line
    cd, line
    print, '------------------- '+line+' -------------------'
    spawn, 'weather'+line
    wait, 600
    cd, '../'
  endwhile

  close, un
  free_lun, un

end
